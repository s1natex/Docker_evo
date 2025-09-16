# ✅ Good request (defaults)
curl "http://localhost:5000/generate"

# ✅ Custom length within bounds
curl "http://localhost:5000/generate?length=20&digits=true&symbols=false&uppercase=true"

# ❌ Too short
curl "http://localhost:5000/generate?length=4"

# ❌ Too long
curl "http://localhost:5000/generate?length=2000"

# ❌ Invalid length (non-int)
curl "http://localhost:5000/generate?length=abc"

# ❌ Invalid boolean
curl "http://localhost:5000/generate?digits=maybe"
