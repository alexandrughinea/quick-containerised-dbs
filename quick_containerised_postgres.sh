#!/bin/bash

# Generate a random database name, username, and password
DB_NAME="db_$(openssl rand -hex 3)"
DB_USER="user_$(openssl rand -hex 3)"
DB_PASS="pass_$(openssl rand -hex 6)"

# Expose a random port between 5432 and 6000
PORT=$(shuf -i 5432-6000 -n 1)

# Print the credentials for reference
echo "Starting PostgreSQL Docker container with:"
echo "Database Name: $DB_NAME"
echo "Username: $DB_USER (Superuser)"
echo "Password: $DB_PASS"
echo "Port: $PORT"

# Run PostgreSQL container in Docker
docker run -d \
  --name postgres_$DB_NAME \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_USER=$DB_USER \
  -e POSTGRES_PASSWORD=$DB_PASS \
  -p $PORT:5432 \
  postgres:latest

# Wait for the container to start
sleep 5

# Get the hostname for Docker, which is usually localhost when running locally
HOST="localhost"

# Append credentials to the ~/.pgpass file
PGPASS_ENTRY="$HOST:$PORT:$DB_NAME:$DB_USER:$DB_PASS"
PGPASS_PATH="$HOME/.pgpass"

# Create ~/.pgpass if it doesn't exist and set the right permissions
if [ ! -f "$PGPASS_PATH" ]; then
    touch "$PGPASS_PATH"
    chmod 600 "$PGPASS_PATH"
fi

# Add the new credentials to ~/.pgpass
echo "$PGPASS_ENTRY" >> "$PGPASS_PATH"

# Output connection details
echo "Credentials added to ~/.pgpass"
echo "To connect: psql -h localhost -p $PORT -U $DB_USER -d $DB_NAME"
echo "Password stored in ~/.pgpass"

# Verify superuser status
echo "Verifying superuser status..."
docker exec postgres_$DB_NAME psql -U $DB_USER -d $DB_NAME -c "SELECT usesuper FROM pg_user WHERE usename = current_user;" | grep -q t && echo "User $DB_USER is confirmed as a superuser." || echo "Warning: $DB_USER is not a superuser."
