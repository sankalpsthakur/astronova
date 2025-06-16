#!/bin/bash
set -e

# Wait for dependencies to be ready
echo "Waiting for dependencies..."

# If Redis is required, wait for it
if [ -n "$REDIS_URL" ]; then
    echo "Waiting for Redis..."
    until nc -z redis 6379; do
        echo "Redis is unavailable - sleeping"
        sleep 1
    done
    echo "Redis is up - continuing"
fi

# Validate required environment variables
if [ -z "$SECRET_KEY" ]; then
    echo "ERROR: SECRET_KEY environment variable is required"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "WARNING: ANTHROPIC_API_KEY not set - some features may not work"
fi

echo "Starting AstroNova FastAPI server..."

# Execute the main command
exec "$@"