#!/bin/bash

# Generate a random Redis database name, username, and password
DB_NAME="db_$(openssl rand -hex 3)"
DB_USER="user_$(openssl rand -hex 3)"
DB_PASS="pass_$(openssl rand -hex 6)"

# Expose a random port between 6379 and 6400
PORT=$(shuf -i 6379-6400 -n 1)

# Print the credentials for reference
echo "Starting Redis Docker container with:"
echo "Database Name: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
echo "Port: $PORT"

# Run Redis container in Docker
docker run -d \
  --name redis_$DB_NAME \
  -e REDIS_PASSWORD=$DB_PASS \
  -p $PORT:6379 \
  redis:latest \
  --requirepass $DB_PASS

# Wait for the container to start
sleep 5

# Get the hostname for Docker, which is usually localhost when running locally
HOST="localhost"

# Append credentials to the ~/.redispass file
REDISPASS_ENTRY="$HOST:$PORT:$DB_USER:$DB_PASS"
REDISPASS_PATH="$HOME/.redispass"

# Create ~/.redispass if it doesn't exist and set the right permissions
if [ ! -f "$REDISPASS_PATH" ]; then
    touch "$REDISPASS_PATH"
    chmod 600 "$REDISPASS_PATH"
fi

# Add the new credentials to ~/.redispass
echo "$REDISPASS_ENTRY" >> "$REDISPASS_PATH"

# Output connection details
echo "Credentials added to ~/.redispass"
echo "To connect: redis-cli -h $HOST -p $PORT -a $DB_PASS"
echo "Password stored in ~/.redispass"
