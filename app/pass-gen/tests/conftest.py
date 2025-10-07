import os
import sys
import types
import importlib.util
import pytest

# ---- Minimal in-memory fake DB to satisfy our app's SQL calls ----
class _FakeCursor:
    def __init__(self, store):
        self.store = store
        self._results = []

    def execute(self, sql, params=None):
        sql = (sql or "").strip().lower()
        params = params or tuple()

        if sql.startswith("create table"):
            return

        if sql.startswith("select"):
            self._results = list(sorted(self.store, key=lambda r: r["created_at"], reverse=True))
            return

        if sql.startswith("insert"):
            name, password = params
            new_id = (self.store[-1]["id"] + 1) if self.store else 1
            from datetime import datetime
            self.store.append({
                "id": new_id,
                "name": name,
                "password": password,
                "created_at": datetime.utcnow(),
            })
            return

        if sql.startswith("delete"):
            del_id = params[0]
            self.store[:] = [r for r in self.store if r["id"] != del_id]
            return

    def fetchall(self):
        return [(r["id"], r["name"], r["password"], r["created_at"]) for r in self._results]

    def __enter__(self): return self
    def __exit__(self, exc_type, exc, tb): return False


class _FakeConn:
    def __init__(self, store):
        self.store = store

    def cursor(self):
        return _FakeCursor(self.store)

    def commit(self): pass
    def __enter__(self): return self
    def __exit__(self, exc_type, exc, tb): return False


@pytest.fixture(scope="function")
def app_module(monkeypatch):
    """
    Load app/pass-gen/app.py as a module with psycopg2.connect patched to our fake.
    Also patches open('db_init.sql') to avoid touching the filesystem during imports.
    """
    store = []

    def fake_connect(dsn):
        return _FakeConn(store)

    try:
        import psycopg2  # noqa
    except Exception:
        psycopg2 = types.ModuleType("psycopg2")
        sys.modules["psycopg2"] = psycopg2

    monkeypatch.setenv("DATABASE_URL", "postgresql://fake:fake@localhost:5432/fake")
    monkeypatch.setattr("psycopg2.connect", fake_connect, raising=False)

    import builtins
    real_open = builtins.open

    class _FakeOpenCtx:
        def __enter__(self): return self
        def __exit__(self, *args): return False
        def read(self): return "/* no-op schema for tests */"

    def fake_open(path, *a, **kw):
        if isinstance(path, str) and path.endswith("db_init.sql"):
            return _FakeOpenCtx()
        return real_open(path, *a, **kw)

    monkeypatch.setattr(builtins, "open", fake_open)

    app_path = os.path.join(os.path.dirname(__file__), "..", "app.py")
    app_path = os.path.abspath(app_path)

    spec = importlib.util.spec_from_file_location("pass_gen_app", app_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture()
def client(app_module):
    app = app_module.app
    app.testing = True
    return app.test_client()
