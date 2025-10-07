#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BACKEND_DIR = ROOT / "app" / "pass-gen"
FRONTEND_DIR = ROOT / "app" / "frontend"

def run(cmd, cwd=None, env=None, name=""):
    print(f"\n=== Running: {name or ' '.join(cmd)} ===")
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, check=False)
        return result.returncode
    except FileNotFoundError as e:
        print(f"[SKIP] {name or cmd[0]} not found: {e}")
        return 127

def which(cmd):
    return shutil.which(cmd)

def npm_command():
    # On Windows, npm is npm.cmd
    if os.name == "nt":
        return which("npm.cmd") or which("npm")
    return which("npm")

def main():
    overall_rc = 0

    # 1) Backend tests (pytest)
    env = os.environ.copy()
    env.setdefault("DATABASE_URL", "postgresql://test:test@localhost:5432/testdb")
    rc_py = run([sys.executable, "-m", "pytest", "-q"], cwd=BACKEND_DIR, env=env, name="pytest (pass-gen)")
    overall_rc |= (rc_py != 0)

    # 2) Frontend tests (only if Node present)
    node_path = which(os.environ.get("NODE_BIN", "node"))
    if not node_path:
        print("[INFO] Node not found; skipping frontend tests.")
        print_summary(rc_py == 0, skipped_fe=True, fe_ok=False)
        sys.exit(0 if rc_py == 0 else 1)

    rc_node = run([node_path, "--version"], name="node version check")
    if rc_node != 0:
        print("[INFO] Node check failed; skipping frontend tests.")
        print_summary(rc_py == 0, skipped_fe=True, fe_ok=False)
        sys.exit(0 if rc_py == 0 else 1)

    # If npm missing, skip FE tests gracefully
    npm = npm_command()
    if not npm:
        print("[INFO] npm not found on PATH; skipping frontend tests.")
        print("       Install Node (with npm) from https://nodejs.org or add npm to PATH.")
        print_summary(rc_py == 0, skipped_fe=True, fe_ok=False)
        sys.exit(0 if rc_py == 0 else 1)

    # Install deps (ci if lock exists, else install)
    lockfile = FRONTEND_DIR / "package-lock.json"
    if lockfile.exists():
        run([npm, "ci", "--no-audit", "--no-fund"], cwd=FRONTEND_DIR, name="npm ci (frontend)")
    else:
        run([npm, "install", "--no-audit", "--no-fund"], cwd=FRONTEND_DIR, name="npm install (frontend)")

    # Run Node tests (explicit path to avoid glob issues on Windows)
    test_file = str((FRONTEND_DIR / "tests" / "server.test.js").resolve())
    rc_fe = run([node_path, "--test", test_file], cwd=FRONTEND_DIR, name="frontend node tests")

    fe_ok = (rc_fe == 0)
    print_summary(rc_py == 0, skipped_fe=False, fe_ok=fe_ok)
    sys.exit(0 if (rc_py == 0 and fe_ok) else 1)

def print_summary(py_ok, skipped_fe=False, fe_ok=False):
    print("\n=== Summary ===")
    print(f"pass-gen (pytest): {'OK' if py_ok else 'FAIL'}")
    if skipped_fe:
        print("frontend (node --test): SKIPPED (npm not found)")
    else:
        print(f"frontend (node --test): {'OK' if fe_ok else 'FAIL'}")

if __name__ == "__main__":
    main()
