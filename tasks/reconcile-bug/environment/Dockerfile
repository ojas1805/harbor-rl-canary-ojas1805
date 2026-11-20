
FROM python:3.12-slim

WORKDIR /app

COPY reconcile.py /app/reconcile.py

RUN chmod +x /app/reconcile.py

CMD ["python", "/app/reconcile.py", "--help"]
