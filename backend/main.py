"""
REVA — FastAPI Backend
Run: uvicorn main:app --host 0.0.0.0 --port 8000
"""

import os
import uuid
import shutil
import subprocess
import tempfile
import datetime
from contextlib import asynccontextmanager

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from scanner import scan_directory


# ── Startup / shutdown ───────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Verify apktool is available at startup
    result = subprocess.run(["apktool", "--version"], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError("apktool not found. Install it and ensure it's on PATH.")
    print(f"apktool version: {result.stdout.strip()}")
    yield
    # Nothing to clean up


app = FastAPI(
    title="REVA API",
    description="Reverse Engineering Vulnerability Analyzer — backend",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health check ─────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok"}


# ── Main scan endpoint ────────────────────────────────────────────────────────
@app.post("/scan")
async def scan(file: UploadFile = File(...)):
    # Validate extension
    if not (file.filename or "").lower().endswith(".apk"):
        raise HTTPException(status_code=400, detail="Only .apk files are accepted.")

    apk_name = file.filename or "unknown.apk"
    scan_id  = uuid.uuid4().hex
    work_dir = os.path.join(tempfile.gettempdir(), f"reva_{scan_id}")
    apk_path = os.path.join(work_dir, "input.apk")
    out_dir  = os.path.join(work_dir, "decompiled")

    os.makedirs(work_dir, exist_ok=True)

    try:
        # 1. Save uploaded APK to disk
        with open(apk_path, "wb") as f:
            content = await file.read()
            f.write(content)

        # Basic magic-byte check — APKs are ZIP files starting with PK\x03\x04
        with open(apk_path, "rb") as f:
            magic = f.read(4)
        if magic[:2] != b"PK":
            raise HTTPException(status_code=400, detail="Uploaded file is not a valid APK/ZIP.")

        # 2. Decompile with apktool
        result = subprocess.run(
            ["apktool", "d", "-f", "-o", out_dir, apk_path],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            raise HTTPException(
                status_code=500,
                detail=f"apktool failed: {result.stderr[-500:]}",
            )

        # 3. Pattern scan
        findings, scanned_files = scan_directory(out_dir)

        # 4. Sort by severity
        sev_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
        findings.sort(key=lambda x: sev_order.get(x.severity, 4))

        return JSONResponse({
            "apk_name":      apk_name,
            "scanned_files": scanned_files,
            "scanned_at":    datetime.datetime.utcnow().isoformat(),
            "findings":      [f.to_dict() for f in findings],
        })

    except HTTPException:
        raise
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="Decompilation timed out (>120s).")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Always clean up temp files
        shutil.rmtree(work_dir, ignore_errors=True)
