#!/bin/bash
# scripts/analyze_logs.sh
# Automated log inspection using predefined patterns (Assignment 6 - 4.4)

echo "--- Starting Automated Log Analysis ---"

PATTERNS=("connection refused" "error" "exception" "failed" "restart" "critical" "timeout")

echo "Searching for critical patterns in service logs..."

for pattern in "${PATTERNS[@]}"; do
    echo "Pattern: [$pattern]"
    docker-compose logs 2>&1 | grep -i "$pattern" | tail -n 5
    echo "----------------------------------------"
done

# Specifically check for DB connection failures
echo "Checking for Database connection failures..."
docker-compose logs | grep -iE "psycopg2.OperationalError|connection to server at|failed to connect" | tail -n 10

echo "--- Log Analysis COMPLETE ---"
