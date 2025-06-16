# AstroNova FastAPI Docker Setup

This directory contains a fully containerized FastAPI backend for the AstroNova application with CORS middleware and environment-driven configuration.

## Quick Start

### 1. Environment Setup

Copy the example environment file and configure your settings:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```bash
# Required - Change these in production
SECRET_KEY=your-secret-key-here-change-in-production
JWT_SECRET_KEY=your-jwt-secret-key-here-change-in-production
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# CORS Configuration (adjust for your frontend domains)
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com

# Optional
DEBUG=false
```

### 2. Run with Docker Compose (Recommended)

```bash
# Build and start all services (API + Redis)
docker-compose up --build

# Run in background
docker-compose up -d --build

# View logs
docker-compose logs -f astronova-api

# Stop services
docker-compose down
```

### 3. Build and Run Docker Container Only

```bash
# Build the Docker image
docker build -t astronova-api .

# Run the container
docker run -p 8080:8080 \
  -e SECRET_KEY="your-secret-key" \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e CORS_ORIGINS="http://localhost:3000" \
  astronova-api
```

## Available Endpoints

Once running, the API will be available at:

- **Health Check:** `GET http://localhost:8080/health`
- **API Documentation:** `GET http://localhost:8080/docs` (Swagger UI)
- **API Schema:** `GET http://localhost:8080/openapi.json`

### Main API Routes

All routes are prefixed with `/api/v1/`:

- `GET /api/v1/horoscope` - Get horoscope data
- `POST /api/v1/chart` - Generate astrological charts  
- `POST /api/v1/chat` - AI chat functionality
- `GET /api/v1/locations` - Location search
- `GET /api/v1/ephemeris` - Planetary ephemeris data
- `POST /api/v1/match` - Compatibility matching
- `GET /api/v1/reports` - Generated reports
- `GET /api/v1/content` - Content management
- `GET /api/v1/misc` - Miscellaneous utilities

## CORS Configuration

The FastAPI application includes CORS middleware with environment-driven origin whitelisting:

```python
# Environment variable CORS_ORIGINS controls allowed origins
CORS_ORIGINS=http://localhost:3000,https://app.example.com,https://example.com
```

### CORS Testing

The CORS middleware handles:
- **Preflight OPTIONS requests** for complex requests
- **Credential support** for authenticated requests  
- **All HTTP methods** (GET, POST, PUT, DELETE, OPTIONS)
- **Custom headers** support

## Rate Limiting

Each endpoint has rate limiting configured:
- Most GET endpoints: 100 requests/hour
- POST endpoints: 10-30 requests/minute depending on complexity
- Uses Redis for distributed rate limiting when available

## Production Deployment

### Environment Variables for Production

```bash
# Security (REQUIRED)
SECRET_KEY=<strong-random-secret-key>
JWT_SECRET_KEY=<strong-random-jwt-secret>
ANTHROPIC_API_KEY=<your-anthropic-api-key>

# CORS (adjust for your domains)
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# Performance
DEBUG=false
REDIS_URL=redis://redis:6379
```

### Health Checks

The container includes health checks:
- **Health endpoint:** `/health` returns `{"status": "ok"}`
- **Docker health check:** Built into the container
- **Dependency checks:** Waits for Redis if configured

### Scaling

For production scaling:

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  astronova-api:
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

## Development

### Local Development with Hot Reload

```bash
# Install dependencies locally
pip install -r requirements.txt

# Run with auto-reload
uvicorn app:app --host 0.0.0.0 --port 8080 --reload
```

### Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run tests
pytest tests/
```

## Troubleshooting

### Common Issues

1. **Import Errors:** Ensure all route files have been converted to FastAPI routers
2. **CORS Issues:** Check `CORS_ORIGINS` environment variable
3. **Rate Limiting:** Redis connection required for distributed rate limiting
4. **Health Check Failures:** Ensure `/health` endpoint is accessible

### Logs

```bash
# View application logs
docker-compose logs astronova-api

# Follow logs in real-time
docker-compose logs -f astronova-api
```

### Port Conflicts

If port 8080 is in use:

```bash
# Use different port
docker run -p 8081:8080 astronova-api
```

## API Migration from Flask

This FastAPI implementation maintains backward compatibility with the original Flask API:
- Same endpoint paths and parameters
- Same response formats
- Enhanced with automatic API documentation
- Improved performance with async operations
- Better error handling and validation