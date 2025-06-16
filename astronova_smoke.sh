#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/backend"

# 1. Python & env
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt pytest pytest-cov pytest-asyncio

# 2. Ephemeris data (example helper; adapt path)
if [ ! -d "./ephemeris" ]; then
  mkdir ephemeris
  if curl -fL -o sepl_18.zip https://example.com/sepl_18.zip; then
    unzip sepl_18.zip -d ephemeris
  else
    echo "Ephemeris download failed; continuing with placeholder"
    touch ephemeris/.placeholder
  fi
fi

# 3. Redis (Docker for portability)
docker run -d --name astronova-redis -p 6379:6379 redis:7

# 4. Export minimal secrets
export SECRET_KEY=dev-secret
export JWT_SECRET_KEY=jwt-secret
export ANTHROPIC_API_KEY=dummy
export REDIS_URL=redis://localhost:6379/0
export FLASK_ENV=testing

# 5. Run unit & integration tests
pytest -v --cov=. --cov-report=xml

# 6. Launch server & ping health-check
python app.py & APP_PID=$!
sleep 5
curl -f http://127.0.0.1:8080/api/v1/misc/health
kill $APP_PID
docker stop astronova-redis && docker rm astronova-redis

echo "✅ Smoke test finished"
