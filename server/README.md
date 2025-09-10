Server (Flask)

- Backend code lives in `server/`
- Entry point: `server/app.py`
- Minimal endpoints: `/api/v1/health`, `/api/v1/horoscope`, `/api/v1/ephemeris/current` (plus stubs for auth, chart, chat, locations, reports, astrology positions)

Run locally
- `pip install -r server/requirements.txt`
- `python server/app.py`

Docker
- Build: `docker build -t astronova-server:dev server/`
- Run: `docker run --rm -p 8080:8080 --name astronova astronova-server:dev`
- Health: `curl http://localhost:8080/api/v1/health` should return `{ "status": "ok" }`

Notes
- The Dockerfile exposes port `8080` and defines a `HEALTHCHECK` that pings `/api/v1/health`.
- Use `-e FLASK_DEBUG=true` with `docker run` for verbose logging during development.
