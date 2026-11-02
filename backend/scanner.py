"""
REVA Pattern Scanner
Walks the decompiled APK directory and matches 10 vulnerability categories.
"""

import os
import re
from dataclasses import dataclass

@dataclass
class Finding:
    id: str
    name: str
    severity: str
    file: str
    line: int
    snippet: str
    description: str
    fix: str

    def to_dict(self):
        return {
            "id":          self.id,
            "name":        self.name,
            "severity":    self.severity,
            "file":        self.file,
            "line":        self.line,
            "snippet":     self.snippet,
            "description": self.description,
            "fix":         self.fix,
        }


VULN_PATTERNS = [
    {
        "id":       "V001",
        "name":     "SQL Injection Risk",
        "severity": "CRITICAL",
        "description": (
            "Raw string concatenation used in a SQL query. An attacker can inject "
            "malicious SQL to read, modify, or delete all database data."
        ),
        "fix": (
            "Use parameterised queries or prepared statements. "
            "Example: db.rawQuery(\"SELECT * FROM users WHERE id = ?\", new String[]{userId})"
        ),
        "patterns": [
            r'rawQuery\s*\(\s*["\'].*?\+',
            r'execSQL\s*\(\s*["\'].*?\+',
            r'"SELECT.*?\+.*?WHERE',
            r'"INSERT\s+INTO.*?\+',
            r'"UPDATE.*?SET.*?\+',
            r'"DELETE.*?WHERE.*?\+',
        ],
        "extensions": {".java", ".kt", ".smali"},
    },
    {
        "id":       "V002",
        "name":     "Hardcoded API Key / Secret",
        "severity": "HIGH",
        "description": (
            "An API key, token, or secret is hardcoded directly in the source. "
            "Anyone who decompiles the APK can extract and abuse it instantly."
        ),
        "fix": (
            "Store secrets server-side. Never embed credentials in client code. "
            "Use Android Keystore or environment variables on the backend."
        ),
        "patterns": [
            r'(?i)(api_key|apiKey|API_KEY)\s*=\s*["\'][A-Za-z0-9_\-]{16,}["\']',
            r'(?i)(secret|SECRET)\s*=\s*["\'][A-Za-z0-9_\-]{16,}["\']',
            r'(?i)(password|passwd|PASSWORD)\s*=\s*["\'][^"\']{6,}["\']',
            r'(?i)(token|TOKEN)\s*=\s*["\'][A-Za-z0-9_\-\.]{20,}["\']',
            r'(?i)private_key\s*=\s*["\'][^"\']{10,}["\']',
        ],
        "extensions": {".java", ".kt", ".smali", ".xml", ".properties", ".gradle"},
    },
    {
        "id":       "V003",
        "name":     "Insecure HTTP Connection",
        "severity": "HIGH",
        "description": (
            "The app communicates over plain HTTP. Traffic can be intercepted and "
            "read by anyone on the same network (man-in-the-middle attack)."
        ),
        "fix": (
            "Replace all http:// URLs with https://. "
            "Enable Android Network Security Config to block cleartext traffic."
        ),
        "patterns": [
            r'http://(?!schemas\.|www\.w3|localhost|10\.|192\.168|127\.)',
            r'URL\s*\(\s*["\']http://',
            r'usesCleartextTraffic\s*=\s*["\']true["\']',
        ],
        "extensions": {".java", ".kt", ".xml", ".smali"},
    },
    {
        "id":       "V004",
        "name":     "Weak Cryptography (MD5 / DES / RC4)",
        "severity": "HIGH",
        "description": (
            "Deprecated or broken cryptographic algorithms detected. "
            "MD5, DES, and RC4 can be cracked with modern computing power."
        ),
        "fix": (
            "Use AES-256 for encryption, SHA-256 or SHA-3 for hashing, "
            "and RSA-2048+ or ECDSA for signatures."
        ),
        "patterns": [
            r'MessageDigest\.getInstance\s*\(\s*["\']MD5["\']',
            r'MessageDigest\.getInstance\s*\(\s*["\']SHA-1["\']',
            r'Cipher\.getInstance\s*\(\s*["\']DES',
            r'Cipher\.getInstance\s*\(\s*["\']RC4',
            r'Cipher\.getInstance\s*\(\s*["\']AES/ECB',
        ],
        "extensions": {".java", ".kt", ".smali"},
    },
    {
        "id":       "V005",
        "name":     "Exported Component Without Permission",
        "severity": "MEDIUM",
        "description": (
            "An Activity, Service, or Receiver is exported without requiring any "
            "permission. Malicious apps can invoke it directly, bypassing security."
        ),
        "fix": (
            "Set android:exported=\"false\" for internal components, or add "
            "android:permission with a custom signature-level permission."
        ),
        "patterns": [
            r'android:exported\s*=\s*["\']true["\']',
        ],
        "extensions": {".xml"},
    },
    {
        "id":       "V006",
        "name":     "Insecure Data Storage",
        "severity": "MEDIUM",
        "description": (
            "Files or SharedPreferences created with MODE_WORLD_READABLE or "
            "MODE_WORLD_WRITEABLE allow any other app on the device to read them."
        ),
        "fix": (
            "Use MODE_PRIVATE for all file and preference operations. "
            "For sensitive data, use EncryptedSharedPreferences."
        ),
        "patterns": [
            r'MODE_WORLD_READABLE',
            r'MODE_WORLD_WRITEABLE',
        ],
        "extensions": {".java", ".kt", ".smali"},
    },
    {
        "id":       "V007",
        "name":     "Disabled SSL Certificate Validation",
        "severity": "CRITICAL",
        "description": (
            "The app overrides SSL/TLS certificate validation, accepting any "
            "certificate including fake ones. HTTPS protection is completely defeated."
        ),
        "fix": (
            "Remove all custom TrustManagers that accept any certificate. "
            "Use Android's default SSL validation."
        ),
        "patterns": [
            r'checkClientTrusted\s*\([^)]*\)\s*\{[\s]*\}',
            r'checkServerTrusted\s*\([^)]*\)\s*\{[\s]*\}',
            r'ALLOW_ALL_HOSTNAME_VERIFIER',
            r'AllowAllHostnameVerifier',
            r'setHostnameVerifier.*ALLOW_ALL',
            r'getAcceptedIssuers\s*\(\s*\)\s*\{[^}]*return\s+null',
        ],
        "extensions": {".java", ".kt", ".smali"},
    },
    {
        "id":       "V008",
        "name":     "Overly Broad Permissions",
        "severity": "LOW",
        "description": (
            "The app requests sensitive permissions that may not be necessary. "
            "This widens the damage if the app is ever compromised."
        ),
        "fix": (
            "Audit each permission. Request only what is absolutely necessary. "
            "Use runtime permissions for sensitive ones."
        ),
        "patterns": [
            r'android\.permission\.READ_CONTACTS',
            r'android\.permission\.READ_SMS',
            r'android\.permission\.SEND_SMS',
            r'android\.permission\.RECORD_AUDIO',
            r'android\.permission\.ACCESS_FINE_LOCATION',
            r'android\.permission\.READ_CALL_LOG',
            r'android\.permission\.PROCESS_OUTGOING_CALLS',
        ],
        "extensions": {".xml"},
    },
    {
        "id":       "V009",
        "name":     "Debug Mode Left Enabled",
        "severity": "LOW",
        "description": (
            "android:debuggable is set to true. Anyone can attach a debugger to "
            "the running app and inspect memory, variables, and runtime state."
        ),
        "fix": (
            "Set android:debuggable=\"false\" in production. "
            "Android release builds do this automatically when properly configured."
        ),
        "patterns": [
            r'android:debuggable\s*=\s*["\']true["\']',
        ],
        "extensions": {".xml"},
    },
    {
        "id":       "V010",
        "name":     "Logging of Sensitive Data",
        "severity": "LOW",
        "description": (
            "Sensitive information (passwords, tokens, personal data) may be written "
            "to Android logs, which are readable by other apps on rooted devices."
        ),
        "fix": (
            "Remove all Log.d/v/i statements from production builds, "
            "especially any that include user data or credentials."
        ),
        "patterns": [
            r'(?i)Log\.[dviwef]\s*\(.*(?:password|passwd|token|secret|key|credit)',
            r'(?i)System\.out\.print.*(?:password|passwd|token|secret)',
            r'printStackTrace\s*\(',
        ],
        "extensions": {".java", ".kt"},
    },
]


def scan_directory(root_dir: str) -> tuple[list[Finding], int]:
    findings: list[Finding] = []
    scanned = 0

    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            fpath = os.path.join(dirpath, filename)
            rel   = os.path.relpath(fpath, root_dir)

            for vuln in VULN_PATTERNS:
                if ext not in vuln["extensions"]:
                    continue
                try:
                    with open(fpath, "r", errors="ignore") as f:
                        lines = f.readlines()
                except OSError:
                    continue

                for lineno, line in enumerate(lines, 1):
                    for pat in vuln["patterns"]:
                        if re.search(pat, line, re.IGNORECASE):
                            findings.append(Finding(
                                id          = vuln["id"],
                                name        = vuln["name"],
                                severity    = vuln["severity"],
                                file        = rel,
                                line        = lineno,
                                snippet     = line.strip()[:140],
                                description = vuln["description"],
                                fix         = vuln["fix"],
                            ))
                            break  # one finding per vuln per line

            scanned += 1

    return findings, scanned
