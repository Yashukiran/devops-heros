# Session 17 – Complete CI/CD & DevSecOps

A full **CI/CD + DevSecOps pipeline** for the course's Flask "DevSecOps Dashboard" app (from [`session-17-devsecops/demo`](../../session-17-devsecops/demo)). Every push is built and tested, then scanned four different ways. A **security gate** decides whether the image may be pushed and deployed.

- **Workflow:** [`.github/workflows/session17-devsecops.yml`](../../.github/workflows/session17-devsecops.yml)
- **Run #1 – blocked by the security gate ❌:** [run 37517776160](https://github.com/Yashukiran/devops-heros/actions/runs/37517776160)
- **Run #2 – all 8 jobs green ✅:** [run 37518207336](https://github.com/Yashukiran/devops-heros/actions/runs/37518207336)
- **Image:** `ghcr.io/yashukiran/session17-devsecops`

---

## Pipeline Flow

```text
Code
 │
 ▼
Build & Unit Test ──────┬──► SAST ─ Bandit ───────────────┐
 (pytest + coverage)    ├──► SCA ─ pip-audit ─────────────┤
                        ├──► Secret Scan ─ Gitleaks ──────┤
                        └──► Docker Build ─► Image Scan ──┤
                                             (Trivy)       ▼
                                                    SECURITY GATE  (one policy, all reports)
                                                           │ pass
                                                           ▼
                                                 Push Image ─ GHCR
                                                           │
                                                           ▼
                                             Deploy to Kubernetes (kind)
```

| Stage | Tool | What it finds |
|---|---|---|
| Build & Unit Test | pytest + pytest-cov | Broken functionality (8 tests) |
| **SAST** (Static Application Security Testing) | **Bandit** | Insecure *code*: debug mode, `eval`, shell injection, hard-coded passwords, weak crypto… |
| **SCA** (Software Composition Analysis) | **pip-audit** | Known CVEs in *dependencies* (Flask, Werkzeug, Jinja2, gunicorn…) |
| **Secret scanning** | **Gitleaks** | API keys, tokens and passwords committed to the code |
| **Container image scanning** | **Trivy** | CVEs in the *image*: OS packages (Debian) and Python packages inside it |
| **Security gate** | [`security/security_gate.py`](security/security_gate.py) | Applies the policy below to all four reports and blocks the release on any violation |
| Push | GHCR + `GITHUB_TOKEN` | Only images that passed the gate are published |
| Deploy | kind + kubectl | Rollout + `/health` and `/api/status` checks |

### Security gate policy

| Check | Blocks the release when… |
|---|---|
| SAST (Bandit) | any **HIGH** severity finding (MEDIUM/LOW are reported, not blocking) |
| SCA (pip-audit) | any dependency has a **known vulnerability** |
| Secrets (Gitleaks) | **any** secret is found |
| Image (Trivy) | any **CRITICAL/HIGH** CVE that **has a fix available** |

The scanners themselves never fail the build. They only produce JSON reports (uploaded as artifacts). That way every scan always runs and you see *all* problems at once, and the decision is made in **one place, with one written policy**. The gate also writes a results table to the run's **Summary** page.

---

## Project Structure

```text
Assignment/DevSecOps/
├── app/                      # Flask app (app.py, templates/, static/)
├── tests/test_app.py         # 8 unit tests
├── security/security_gate.py # the security gate policy
├── k8s/
│   ├── deployment.yaml       # hardened: non-root, read-only FS, no capabilities, probes, limits
│   └── service.yaml
├── Dockerfile                # multi-stage, patched, no pip, non-root, gunicorn
├── requirements.txt          # Flask, gunicorn (pinned)
├── requirements-dev.txt      # + pytest, pytest-cov
└── pytest.ini
```

---

## What the scans actually found (and how I fixed it)

### Finding 1 – SAST: Flask debug mode (Bandit **HIGH**, B201)

The course app ended with:

```python
app.run(host="0.0.0.0", port=5001, debug=True)
```

- **B201 (HIGH):** `debug=True` exposes the **Werkzeug debugger**, which lets anyone who can reach it **run arbitrary Python code** on the server.
- **B104 (MEDIUM):** binding to `0.0.0.0` listens on every network interface.

**Run #1 was blocked:** all scan jobs completed, the **Security Gate failed** on the HIGH finding, and **Push and Deploy were skipped**. The vulnerable app was never published.

**Fix:** the debugger is opt-in (`FLASK_DEBUG=1`), the dev server listens on `127.0.0.1` by default, and production runs under **gunicorn** (no debugger at all):

```python
app.run(
    host=os.environ.get("HOST", "127.0.0.1"),
    port=int(os.environ.get("PORT", "5001")),
    debug=os.environ.get("FLASK_DEBUG") == "1",
)
```

**Run #2 passed the gate.** The remaining 5 LOW findings are B311 (`random` used to pick a greeting). That's fine here because it isn't used for anything security-related.

### Finding 2 – Image scan: vulnerable packages inside the base image (Trivy HIGH)

The first local Trivy scan of a simple `python:3.12-slim` image found 4 fixable HIGH CVEs (`urllib3`, `msgpack`, `setuptools`). They didn't come from the app. They were **pip's own vendored copies** and **ensurepip's bundled wheels** shipped in the base image.

**Fix: a hardened multi-stage Dockerfile.**
- **Build stage:** installs the dependencies into `/opt/venv`, then removes pip from the venv.
- **Runtime stage:**
  - `apt-get upgrade` patches the OS packages.
  - **pip, setuptools and ensurepip are removed**: nothing gets installed at runtime, so they're only attack surface.
  - It copies in just the venv and the app.
  - Runs as **non-root UID 10001**.
  - Has a `HEALTHCHECK`.
  - Uses **gunicorn** instead of the Flask dev server.

Result: **0 fixable CRITICAL/HIGH** vulnerabilities.

### SCA and secrets

- `pip-audit`: **8 packages audited, no known vulnerabilities** (Flask 3.1.3, Werkzeug 3.1.x, Jinja2 3.1.6, gunicorn 23.0.0 …).
- `gitleaks`: **no leaks found**.

---

## Gate output (run #2)

```text
| Check   | Tool      | Blocking findings | Result  | Details                            |
|---------|-----------|-------------------|---------|------------------------------------|
| SAST    | Bandit    | 0                 | ✅ PASS | HIGH=0 MEDIUM=0 LOW=5              |
| SCA     | pip-audit | 0                 | ✅ PASS | 8 packages audited                 |
| Secrets | Gitleaks  | 0                 | ✅ PASS | working tree scanned               |
| Image   | Trivy     | 0                 | ✅ PASS | CRITICAL/HIGH with a fix available |

Gate: ✅ PASSED – release allowed
```

---

## Kubernetes hardening (`k8s/deployment.yaml`)

```yaml
securityContext:              # pod
  runAsNonRoot: true
  runAsUser: 10001
  seccompProfile: { type: RuntimeDefault }
containers:
  - securityContext:          # container
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true      # /tmp is an emptyDir for gunicorn
      capabilities: { drop: ["ALL"] }
automountServiceAccountToken: false     # the app never talks to the K8s API
```

Plus readiness/liveness probes on `/health` and CPU/memory requests and limits. I tested it locally with `docker run --read-only --cap-drop ALL --security-opt no-new-privileges`, and the app runs normally.

---

## Run it locally

```bash
pip install -r requirements-dev.txt bandit pip-audit
pytest -v --cov=app
mkdir reports
bandit -r app -f json -o reports/bandit.json
pip-audit -r requirements.txt -f json -o reports/pip-audit.json
docker run --rm -v "$PWD:/src" zricethezav/gitleaks dir /src --report-format json --report-path /src/reports/gitleaks.json
docker build -t session17-devsecops:local .
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD/reports:/out" aquasec/trivy image \
  --ignore-unfixed --severity CRITICAL,HIGH --format json -o /out/trivy.json session17-devsecops:local
python security/security_gate.py reports
```

---

## What I Learned

1. **DevSecOps = shift security left.** Each scanner checks a different layer: my **code** (SAST), **other people's code** (SCA), **what I accidentally committed** (secrets) and **what I ship** (the image).
2. **A security gate turns scan results into a decision.** Without one, scanners just produce reports nobody reads. With one, a vulnerable build **can't** reach the registry or the cluster. Run #1 proved it: push and deploy were skipped.
3. Having scanners only **report** and a single gate **decide** gives one written, reviewable policy. You also see every finding in one run instead of fixing them one failure at a time.
4. **Severity + fixability** makes a sensible policy. Blocking on every LOW or unfixable CVE causes alert fatigue, and people start bypassing the gate.
5. **Base images bring their own vulnerabilities.** Multi-stage builds, patching, removing unneeded tools (pip) and running as non-root can shrink them to zero fixable HIGH/CRITICAL.
6. **Framework defaults can be dangerous.** `debug=True` is fine on a laptop and a remote-code-execution hole in production. Use a real WSGI server (gunicorn) in containers.
7. Security continues **at runtime**: a non-root user, a read-only filesystem, dropped capabilities and no service-account token limit the damage even if the app is compromised.
8. Secrets belong in the platform (`GITHUB_TOKEN`, repository secrets), never in code. Gitleaks checks that on every commit.
