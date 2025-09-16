FROM python:3.12-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/opt/venv/bin:${PATH}"
WORKDIR /app
RUN addgroup --system app && adduser --system --ingroup app --home /app app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app . /app
USER app
EXPOSE 5000
CMD ["flask","--app","app","run","--host=0.0.0.0","--port=5000"]
