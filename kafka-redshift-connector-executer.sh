#!/bin/bash

# Install gettext-base if not already installed
if ! command -v envsubst &> /dev/null; then
    echo "Installing gettext-base..."
    sudo apt-get update
    sudo apt-get install -y gettext-base
else
    echo "gettext-base is already installed."
fi

# Consume messages from the 'client' topic from the beginning
kcat -C -b localhost:9092 -t client -o beginning -e

# Function to check if a port is in use and kill the process using it
kill_port() {
  PORT=$1
  PID=$(lsof -t -i :$PORT)
  if [ -n "$PID" ]; then
    echo "Port $PORT is in use by PID $PID. Killing the process..."
    kill -9 $PID
  else
    echo "Port $PORT is free."
  fi
}

# Check and kill any process using port 8083
kill_port 8083

# Read the parameters.toml file
eval $(grep -A 3 "\[redshift\]" parameters.toml | grep -E "url|user|password" | awk -F '=' '{gsub(/ /, "", $0); print "export REDSHIFT_" toupper($1) "=" $2}')

# Export the environment variables
export REDSHIFT_URL
export REDSHIFT_USER
export REDSHIFT_PASSWORD

# Use a temporary file to expand the properties file
TEMP_FILE=$(mktemp)
envsubst < redshift-kafka-connector/configuration/redshift-sink-connector.properties > "$TEMP_FILE"

# Moving to the correct directory
cd redshift-kafka-connector/configuration

# Start Kafka Connect standalone worker using the temporary file
../kafka_2.13-3.1.0/bin/connect-standalone.sh connect.properties "$TEMP_FILE" &

# Wait briefly to ensure Kafka Connect starts properly
sleep 10

# Remove the temporary file
rm "$TEMP_FILE"
