# ---------- build stage: install dependencies into a virtualenv ----------
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt \
 && /opt/venv/bin/pip uninstall -y pip setuptools

# ---------- runtime stage: only what the app needs ----------
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH

# patch OS packages and remove the package installer (and its vendored libraries) –
# nothing is installed at runtime, so pip is only attack surface
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* \
 && python -m pip uninstall -y pip setuptools wheel || true \
 && rm -rf /usr/local/lib/python3.12/ensurepip /usr/local/bin/pip*

COPY --from=builder /opt/venv /opt/venv

WORKDIR /srv
COPY app ./app

# never run as root
RUN useradd --create-home --uid 10001 appuser
USER 10001

EXPOSE 5001
HEALTHCHECK --interval=15s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5001/health')"

# production WSGI server, no Flask debugger
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "app.app:app"]
