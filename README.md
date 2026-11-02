# REVA — Reverse Engineering Vulnerability Analyzer

> Scan any Android APK for common security vulnerabilities **directly from your phone** — no desktop tooling, no security expertise.

REVA is a mobile-first static analysis tool. A Flutter Android app uploads an APK to a FastAPI backend, which decompiles it with `apktool` and runs pattern-based scanning across 10 vulnerability categories aligned with the [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10). Results come back as a severity-ranked report with remediation advice, exportable as a PDF.

![Status](https://img.shields.io/badge/status-mini%20project-blue)
![Flutter](https://img.shields.io/badge/client-Flutter-02569B)
![FastAPI](https://img.shields.io/badge/backend-FastAPI-009688)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Table of Contents

- [Why REVA?](#why-reva)
- [Features](#features)
- [Architecture](#architecture)
- [Vulnerability Categories](#vulnerability-categories)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Evaluation](#evaluation)
- [Limitations](#limitations)
- [Roadmap](#roadmap)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Team](#team)
- [License](#license)

---

## Why REVA?

Professional Android security tools (MobSF, FlowDroid, Androguard, QARK) are powerful but desktop-bound and built for security experts. Students and small teams — who ship a large share of Android apps — often have no practical way to check an APK before release.

REVA's contribution is **accessibility, not a new detection technique**: the phone you build the app for is also the device you audit it from. It trades the precision of taint analysis for speed, simplicity, and zero desktop setup, making it a fast **first-pass triage tool**, not a replacement for a full audit.

## Features

- Select and scan any APK from your phone's file picker
- 10 OWASP-aligned vulnerability checks (regex-based static analysis)
- Severity-ranked findings: **Critical / High / Medium / Low**
- Each finding shows file, line number, code snippet, description, and a fix
- Filter findings by severity; expandable finding cards
- On-device **PDF export** — no extra server round-trip
- **No data retention**: uploads and decompiled output are deleted after every scan

## Architecture

```
┌────────────────────────┐   multipart/form-data   ┌──────────────────────────────┐
│  Flutter Android App   │ ──────────────────────▶ │  FastAPI Backend             │
│                        │                         │                              │
│  Home → Scan → Report  │                         │  POST /scan                  │
│  (+ PDF export)        │ ◀────────────────────── │   ├─ validate (ext + magic)  │
└────────────────────────┘      JSON findings      │   ├─ apktool decompile       │
                                                   │   ├─ regex pattern scanner   │
                                                   │   └─ cleanup (finally)       │
                                                   └──────────────────────────────┘
```

The two-tier design exists because Android's app sandbox can't run `apktool` (a Java CLI) on-device, so decompilation and scanning run on a backend host.

**Privacy:** each scan runs in a unique temp directory (`/tmp/reva_<uuid>/`) that is removed in a `finally` block — on success, failure, or timeout.

## Vulnerability Categories

| ID | Category | Severity |
|----|----------|----------|
| V001 | SQL Injection Risk | Critical |
| V002 | Hardcoded API Key / Secret | High |
| V003 | Insecure HTTP Connection | High |
| V004 | Weak Cryptography (MD5 / SHA-1 / DES / RC4 / AES-ECB) | High |
| V005 | Exported Component Without Permission | Medium |
| V006 | Insecure Data Storage (`MODE_WORLD_*`) | Medium |
| V007 | Disabled SSL Certificate Validation | Critical |
| V008 | Overly Broad Permissions | Low |
| V009 | Debug Mode Left Enabled | Low |
| V010 | Logging of Sensitive Data | Low |

Each rule is a set of case-insensitive regexes scoped to relevant file extensions (e.g. SQLi patterns only run on `.java` / `.kt` / `.smali`; permission patterns only on `.xml`).

## Getting Started

### Prerequisites

| Component | Requirement |
|-----------|-------------|
| Backend host | Python 3.10+, OpenJDK 17+, [apktool](https://apktool.org) on `PATH`, 4 GB RAM (8 GB recommended) |
| Client | Flutter 3.x, Android 8.0 (API 26)+ device or emulator |
| Network | Phone and backend host on the **same Wi-Fi network** |

### 1. Start the backend

```bash
cd backend
pip install fastapi uvicorn python-multipart
apktool --version          # verify apktool is on PATH
uvicorn main:app --host 0.0.0.0 --port 8000
```

Note the host machine's local IP (`ipconfig` / `ifconfig`). The server refuses to start if `apktool` is missing.

### 2. Run the Flutter app

```bash
cd app
# Set the backend base URL in lib/services/api_service.dart, e.g.
#   http://192.168.x.x:8000
flutter pub get
flutter run --release
```

> The current deployment uses plain HTTP on a local network. For anything beyond local use, put the backend behind HTTPS.

## Usage

1. Open REVA and tap the file area to pick an APK.
2. Tap **Scan** — the upload progress bar runs, then "Decompiling and scanning…".
3. Review the severity summary, filter by severity, and tap a card for details.
4. Tap the export button to generate and share a PDF report.

<!-- Add screenshots here -->
<!-- ![Home](docs/screenshots/home.png) ![Report](docs/screenshots/report.png) -->

## API Reference

### `GET /health`
Connectivity check.

### `POST /scan`
`Content-Type: multipart/form-data` with an APK file.

**Response `200`:**

```json
{
  "apk_name": "example.apk",
  "scanned_files": 412,
  "scanned_at": "2026-01-01T12:00:00Z",
  "findings": [
    {
      "id": "V001",
      "name": "SQL Injection Risk",
      "severity": "CRITICAL",
      "file": "smali/com/example/Db.smali",
      "line": 87,
      "snippet": "db.rawQuery(\"SELECT * FROM users WHERE name = '\" + name ...",
      "description": "Raw string concatenation used in a SQL query...",
      "fix": "Use parameterised queries or prepared statements..."
    }
  ]
}
```

**Errors:** `400` invalid file type / magic bytes · `500` apktool failure · `504` apktool timeout (120 s).

## Evaluation

> Small-scale, proof-of-concept evaluation — see [Limitations](#limitations).

**Detection (controlled corpus).** 48 planted code cases across all 10 categories: 26 deliberately vulnerable + 22 safe "lookalike" constructs designed to trip the regexes.

| Metric | Result |
|--------|--------|
| Overall precision | 0.75 |
| Overall recall | 0.92 |
| Lowest precision | V001 SQLi, V006 Storage (0.50) |
| Highest precision | V003, V004, V008, V009, V010 (1.00) |

Lower precision in V001/V006 is expected: broad textual patterns can't tell attacker-controlled input from hardcoded constants.

**Scan time (end-to-end, tap → report), real F-Droid APKs:**

| APK size | Time |
|----------|------|
| 7 MB | 70 s |
| 11.5 MB | 62 s |
| 16 MB | 74 s |
| 25 MB | 123 s |

`apktool` decompilation dominates; the regex pass itself is cheap.

**Ground-truth validation (in progress).** A mapping of documented vulnerabilities from public vulnerable apps (InsecureBankv2, DIVA, AndroGoat, InjuredAndroid, OVAA, InsecureShop, Sieve, OWASP UnCrackable L1–L3, Damn Vulnerable Bank) and real CVEs (ownCloud, Nextcloud) to REVA's categories is tracked in `docs/REVA_Vulnerable_App_Ground_Truth.xlsx`.

## Limitations

- **Pattern matching, not data-flow analysis** — expect false positives, and false negatives on obfuscated or string-split code.
- Obfuscated APKs (ProGuard/R8) may reduce detection, especially name-based rules like V002.
- Static only — no runtime/dynamic analysis.
- Evaluation corpus was hand-written by the authors; independent ground-truth validation is ongoing.
- Local-network deployment; no authentication on the backend.
- V008 is a literal permission-string match against 7 dangerous permissions.

## Roadmap

- [ ] AST-based analysis to cut false positives (starting with V001, V002, V006)
- [ ] Dynamic analysis alongside static
- [ ] Cloud-hosted backend with authentication / HTTPS
- [ ] iOS IPA support
- [ ] CVE / CWE mapping in reports
- [ ] APK-to-APK comparison for security regressions
- [ ] Opt-in scan history

## Project Structure

> Adjust to match your repo layout.

```
REVA/
├── app/                    # Flutter client
│   └── lib/
│       ├── screens/        # Home, Scan, Report
│       ├── services/       # api_service.dart, pdf_service.dart
│       ├── models/         # Finding, ScanResult
│       └── widgets/        # FindingCard, SeverityBadge, SummaryCard
├── backend/
│   ├── main.py             # FastAPI server (/scan, /health)
│   └── scanner.py          # Pattern engine (VULN_PATTERNS)
├── docs/                   # Report, paper, ground-truth workbook
└── README.md
```


## License

Released under the [MIT License](LICENSE).

## Acknowledgements

[OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10), [apktool](https://apktool.org), [Flutter](https://flutter.dev), [FastAPI](https://fastapi.tiangolo.com), and the maintainers of the public vulnerable apps used for validation.
