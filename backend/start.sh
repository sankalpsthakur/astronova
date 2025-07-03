#!/bin/bash
# Render deployment startup script

echo "Starting AstroNova Backend..."
echo "Python version: $(python --version)"
echo "Working directory: $(pwd)"
echo "Environment: $FLASK_ENV"

# Set default port if not provided
export PORT=${PORT:-8080}

# Run the Flask application
exec python app.py