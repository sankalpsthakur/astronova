#!/bin/bash
# Render deployment startup script

echo "Starting AstroNova Backend..."
echo "Python version: $(python --version)"
echo "Working directory before cd: $(pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
echo "Working directory: $(pwd)"
echo "Environment: $FLASK_ENV"

# Set default port if not provided
export PORT=${PORT:-8080}

# Run the Flask application
exec python app.py
