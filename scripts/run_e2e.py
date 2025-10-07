#!/usr/bin/env python3
"""
Runtime E2E tests for the password generator stack.

Usage (after `docker compose up -d`):
    python ./scripts/run_e2e.py
or with custom endpoints:
    FRONTEND_URL=http://localhost:8080 BACKEND_URL=http://localhost:5050 python ./scripts/run_e2e.py

What this tests:
  1) Backend health responds (5000 by default).
  2) Frontend health responds (3000 by default).
  3) /api/generate on the frontend respects length & charset flags.
  4) Save -> List -> Delete via the frontend proxy (/api/passwords) works.

Exit code is non-zero on failure.
"""

import json
import os
import random
import re
import string
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Callable, Dict, Optional, Tuple

FRONTEND_URL = os.environ.get("FRONTEND_URL", "http://localhost:3000").rstrip("/")
BACKEND_URL = os.environ.get("BACKEND_URL", "http://localhost:5000").rstrip("/")
TIMEOUT_SECS = float(os.environ.get("E2E_TIMEOUT_SECS", "20.0"))

def _req(url: str, method: str = "GET", json_body: Optional[dict] = None, headers: Optional[Dict[str, str]] = None, timeout: float = 5.0) -> Tuple[int, Dict[str, str], bytes]:
    h = {"Accept": "application/json"}
    if headers:
        h.update(headers)
    data_bytes = None
    if json_body is not None:
        body = json.dumps(json_body).encode("utf-8")
        data_bytes = body
        h["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data_bytes, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status = resp.getcode()
            headers = dict(resp.headers.items())
            body = resp.read()
            return status, headers, body
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers.items()) if e.headers else {}, e.read() or b""
    except urllib.error.URLError as e:
        raise RuntimeError(f"Request to {url} failed: {e}")

def _get_json(url: str, timeout: float = 5.0):
    status, _, body = _req(url, "GET", timeout=timeout)
    if status < 200 or status >= 300:
        raise AssertionError(f"GET {url} -> {status}, body={body!r}")
    try:
        return json.loads(body.decode("utf-8"))
    except Exception:
        raise AssertionError(f"GET {url} returned non-JSON body: {body[:200]!r}")

def _post_json(url: str, payload: dict, timeout: float = 5.0):
    status, _, body = _req(url, "POST", json_body=payload, timeout=timeout)
    if status < 200 or status >= 300:
        raise AssertionError(f"POST {url} -> {status}, body={body!r}")
    return json.loads(body.decode("utf-8")) if body else {}

def _delete(url: str, timeout: float = 5.0):
    status, _, body = _req(url, "DELETE", timeout=timeout)
    if status < 200 or status >= 300:
        raise AssertionError(f"DELETE {url} -> {status}, body={body!r}")
    return json.loads(body.decode("utf-8")) if body else {}

def _wait_for(predicate: Callable[[], bool], timeout: float = TIMEOUT_SECS, step: float = 0.2, label: str = "service"):
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            if predicate():
                return True
        except Exception:
            pass
        time.sleep(step)
    raise TimeoutError(f"Timed out waiting for {label} after {timeout}s")

LOWER = set(string.ascii_lowercase)
UPPER = set(string.ascii_uppercase)
DIGITS = set(string.digits)
SYMBOLS = set(string.punctuation)

def _charset_ok(pwd: str, want_digits: bool, want_symbols: bool, want_upper: bool) -> bool:
    s = set(pwd)
    if not want_digits and s & DIGITS:
        return False
    if not want_symbols and s & SYMBOLS:
        return False
    if not want_upper and s & UPPER:
        return False
    if (not want_digits) and (not want_symbols) and (not want_upper):
        return bool(pwd) and all(ch in LOWER for ch in pwd)
    return True

@dataclass
class TestResult:
    name: str
    ok: bool
    detail: str = ""

def check_backend_health() -> TestResult:
    name = "backend /health"
    url = f"{BACKEND_URL}/health"
    try:
        _wait_for(lambda: _get_json(url).get("status") == "ok", label=name)
        return TestResult(name, True)
    except Exception as e:
        return TestResult(name, False, str(e))

def check_frontend_health() -> TestResult:
    name = "frontend /health"
    url = f"{FRONTEND_URL}/health"
    try:
        _wait_for(lambda: _get_json(url).get("status") == "ok", label=name)
        return TestResult(name, True)
    except Exception as e:
        return TestResult(name, False, str(e))

def check_generate_params() -> TestResult:
    name = "frontend /api/generate respects params"
    try:
        qs1 = urllib.parse.urlencode({
            "length": 22,
            "digits": "false",
            "symbols": "false",
            "uppercase": "true",
        })
        j1 = _get_json(f"{FRONTEND_URL}/api/generate?{qs1}")
        pwd1 = j1.get("password", "")
        if len(pwd1) != 22:
            return TestResult(name, False, f"expected length 22, got {len(pwd1)}")
        if not _charset_ok(pwd1, want_digits=False, want_symbols=False, want_upper=True):
            return TestResult(name, False, f"charset did not match for case1: {pwd1!r}")

        qs2 = urllib.parse.urlencode({
            "length": 16,
            "digits": "false",
            "symbols": "false",
            "uppercase": "false",
        })
        j2 = _get_json(f"{FRONTEND_URL}/api/generate?{qs2}")
        pwd2 = j2.get("password", "")
        if len(pwd2) != 16:
            return TestResult(name, False, f"expected length 16, got {len(pwd2)}")
        if not re.fullmatch(r"[a-z]{16}", pwd2):
            return TestResult(name, False, f"expected all lowercase for case2, got {pwd2!r}")

        qs3 = urllib.parse.urlencode({
            "length": 30,
            "digits": "true",
            "symbols": "true",
            "uppercase": "true",
        })
        j3 = _get_json(f"{FRONTEND_URL}/api/generate?{qs3}")
        pwd3 = j3.get("password", "")
        if len(pwd3) != 30:
            return TestResult(name, False, f"expected length 30, got {len(pwd3)}")
        return TestResult(name, True)
    except Exception as e:
        return TestResult(name, False, str(e))

def check_save_list_delete() -> TestResult:
    name = "save->list->delete via frontend proxy"
    try:
        rand = "".join(random.choice(string.ascii_lowercase + string.digits) for _ in range(6))
        test_name = f"e2e-{rand}"
        test_pwd = f"E2e!{rand}A9"

        res_save = _post_json(f"{FRONTEND_URL}/api/passwords", {"name": test_name, "password": test_pwd})
        if res_save.get("status") != "saved":
            return TestResult(name, False, f"save failed: {res_save}")

        items = _get_json(f"{FRONTEND_URL}/api/passwords")
        match = None
        for it in items:
            if it.get("name") == test_name:
                match = it
                break
        if not match:
            return TestResult(name, False, f"saved item not found in list; list size={len(items)}")

        _delete(f"{FRONTEND_URL}/api/passwords/{match['id']}")
        items2 = _get_json(f"{FRONTEND_URL}/api/passwords")
        if any(it.get("id") == match["id"] for it in items2):
            return TestResult(name, False, "item still present after delete")

        return TestResult(name, True)
    except Exception as e:
        return TestResult(name, False, str(e))

def main():
    tests = [
        check_backend_health,
        check_frontend_health,
        check_generate_params,
        check_save_list_delete,
    ]
    results = []
    print(f"Target FRONTEND_URL={FRONTEND_URL}")
    print(f"Target BACKEND_URL={BACKEND_URL}")
    print("Waiting for services and running E2E checks...\n")

    for t in tests:
        sys.stdout.write(f"- {t.__name__} ... ")
        sys.stdout.flush()
        res = t()
        results.append(res)
        print("OK" if res.ok else "FAIL")
        if not res.ok and res.detail:
            print(f"  -> {res.detail}")

    print("\n=== E2E Summary ===")
    ok = True
    for r in results:
        line = ("PASS" if r.ok else "FAIL") + "  " + r.name
        if (r.detail and not r.ok):
            line += "  :: " + r.detail
        print(line)
        ok = ok and r.ok

    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main()
