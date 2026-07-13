#!/bin/bash
# Simple health check script for backend polling
# Returns exit code 0 if successful, 1 if not

URL="http://localhost:5001/api/books"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" -eq 200 ]; then
    echo "Backend is healthy!"
    exit 0
else
    echo "Backend is not healthy yet. Status code: $STATUS"
    exit 1
fi
