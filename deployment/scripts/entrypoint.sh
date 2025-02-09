#!/bin/bash
set -e
set -o pipefail
set -o nounset

# Function to check if PostgreSQL is ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to become available..."

    while ! pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" > /dev/null 2>&1; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 1
    done

    echo "PostgreSQL is up and running!"
}

# Check if Redis is ready
wait_for_redis() {
    echo "Waiting for Redis to become available..."

    while ! nc -z "$REDIS_HOST" "$REDIS_PORT"; do
        echo "Redis is unavailable - sleeping"
        sleep 1
    done

    echo "Redis is up and running!"
}

# Check if ChromaDB is ready
wait_for_chroma() {
    echo "Waiting for ChromaDB to become available..."

    while ! nc -z "$CHROMA_HOST" "$CHROMA_PORT"; do
        echo "ChromaDB is unavailable - sleeping"
        sleep 1
    done

    echo "ChromaDB is up and running!"
}

# Wait for all dependencies
wait_for_postgres
wait_for_redis
wait_for_chroma

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser --noinput

# Create default admin user
python manage.py shell -c "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin')"

# Execute the main command
exec "$@"
