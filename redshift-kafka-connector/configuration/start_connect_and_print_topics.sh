#!/bin/bash

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


# Start Kafka Connect standalone worker
../kafka_2.13-3.1.0/bin/connect-standalone.sh connect.properties redshift-sink-connector.properties &

# Wait for Kafka Connect to start (adjust sleep time as needed)
sleep 30
