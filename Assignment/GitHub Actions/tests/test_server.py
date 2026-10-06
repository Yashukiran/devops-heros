import json
import threading
import urllib.error
import urllib.request

import pytest

from app.server import make_server


@pytest.fixture(scope="module")
def base_url():
    server = make_server(port=0)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_address[1]}"
    server.shutdown()


def get(url):
    with urllib.request.urlopen(url) as r:
        return r.status, json.loads(r.read())


def test_health(base_url):
    assert get(f"{base_url}/health")[1]["status"] == "ok"


def test_api_add(base_url):
    status, body = get(f"{base_url}/api/add?a=10&b=5")
    assert status == 200 and body["result"] == 15


def test_api_divide_by_zero(base_url):
    with pytest.raises(urllib.error.HTTPError) as e:
        get(f"{base_url}/api/divide?a=1&b=0")
    assert e.value.code == 400


def test_unknown_operation(base_url):
    with pytest.raises(urllib.error.HTTPError) as e:
        get(f"{base_url}/api/power?a=2&b=3")
    assert e.value.code == 404
