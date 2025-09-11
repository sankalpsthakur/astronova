FROM python:3.11-slim

# Ensure Python output is unbuffered and avoid .pyc files
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

EXPOSE 8080

# Basic container healthcheck against the app's health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import os, urllib.request, sys; \
port=os.environ.get('PORT','8080'); \
url='http://127.0.0.1:'+port+'/api/v1/health'; \
\
try: \
    r=urllib.request.urlopen(url, timeout=3); \
    sys.exit(0 if r.status==200 else 1) \
except Exception: \
    sys.exit(1)"

CMD ["python", "-u", "app.py"]
