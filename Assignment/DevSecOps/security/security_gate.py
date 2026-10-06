"""Security gate: reads the scanner reports and blocks the release on policy violations.

Policy
  SAST   (Bandit)    : no HIGH severity findings
  SCA    (pip-audit) : no known vulnerable dependencies
  Secrets(Gitleaks)  : no secrets
  Image  (Trivy)     : no CRITICAL/HIGH vulnerabilities that have a fix available

Usage: python security_gate.py <reports-dir>
"""
import json
import os
import sys
from pathlib import Path


def load(path):
    p = Path(path)
    if not p.exists():
        return None
    text = p.read_text(encoding="utf-8").strip()
    return json.loads(text) if text else []


def main(reports):
    rows, failed = [], False

    def check(name, tool, found, detail):
        nonlocal failed
        ok = found == 0
        failed |= not ok
        rows.append((name, tool, found, "PASS" if ok else "FAIL", detail))

    bandit = load(f"{reports}/bandit.json") or {"results": []}
    sev = {}
    for r in bandit["results"]:
        sev[r["issue_severity"]] = sev.get(r["issue_severity"], 0) + 1
    high = [f'{r["test_id"]} {r["filename"]}:{r["line_number"]} {r["issue_text"]}'
            for r in bandit["results"] if r["issue_severity"] == "HIGH"]
    check("SAST", "Bandit", len(high),
          f'HIGH={sev.get("HIGH", 0)} MEDIUM={sev.get("MEDIUM", 0)} LOW={sev.get("LOW", 0)}')

    audit = load(f"{reports}/pip-audit.json") or {"dependencies": []}
    vulns = [f'{d["name"]} {d["version"]}: {v["id"]}'
             for d in audit["dependencies"] for v in d.get("vulns", [])]
    check("SCA", "pip-audit", len(vulns), f'{len(audit["dependencies"])} packages audited')

    leaks = load(f"{reports}/gitleaks.json") or []
    secrets = [f'{l["RuleID"]} {l["File"]}:{l["StartLine"]}' for l in leaks]
    check("Secrets", "Gitleaks", len(secrets), "working tree scanned")

    trivy = load(f"{reports}/trivy.json") or {"Results": []}
    img = [f'{v["VulnerabilityID"]} {v["PkgName"]} {v["InstalledVersion"]}->{v.get("FixedVersion")} ({v["Severity"]})'
           for res in trivy.get("Results", []) for v in (res.get("Vulnerabilities") or [])
           if v["Severity"] in ("CRITICAL", "HIGH") and v.get("FixedVersion")]
    check("Image", "Trivy", len(img), "CRITICAL/HIGH with a fix available")

    lines = ["## Security Gate", "", "| Check | Tool | Blocking findings | Result | Details |",
             "|---|---|---|---|---|"]
    lines += [f"| {a} | {b} | {c} | {'✅' if d == 'PASS' else '❌'} {d} | {e} |" for a, b, c, d, e in rows]
    for title, items in (("Bandit HIGH", high), ("Vulnerable packages", vulns),
                         ("Secrets", secrets), ("Image CVEs", img)):
        if items:
            lines += ["", f"**{title}:**"] + [f"- `{i}`" for i in items]
    lines += ["", f"**Gate: {'❌ FAILED – release blocked' if failed else '✅ PASSED – release allowed'}**"]
    report = "\n".join(lines)

    print(report)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as f:
            f.write(report + "\n")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "reports"))
