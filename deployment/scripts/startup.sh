#!/bin/bash
set -e

# Run with Gunicorn for django
gunicorn \
    --reload \
    --bind 0.0.0.0:8080 \
    --access-logfile - \
    --error-logfile - \
    --log-level DEBUG \
    --timeout 120 \
    --workers 4 \
    --worker-class eventlet \
    src.config.wsgi
