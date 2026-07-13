#!/bin/sh
# Simple health check script for frontend polling
# Returns exit code 0 if successful, 1 if not

URL="http://localhost:80"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" -eq 200 ]; then
    echo "Frontend is healthy!"
    exit 0
else
    echo "Frontend is not healthy yet. Status code: $STATUS"
    exit 1
fi
