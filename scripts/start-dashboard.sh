#!/bin/bash
# Hermes Dashboard Auto-Start Script
# Place in ~/Library/LaunchAgents/

cd /Users/mac/Projects/hermes-dashboard

# Kill existing instance if running
PORT=9863
PID=$(lsof -ti:$PORT 2>/dev/null)
if [ -n "$PID" ]; then
    kill $PID 2>/dev/null
    sleep 1
fi

# Start server
python3 server.py >> /tmp/hermes-dashboard.log 2>&1 &

# Wait for server to start
sleep 2

# Open dashboard in default browser
open http://127.0.0.1:$PORT
