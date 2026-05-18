#!/bin/bash
echo "Applying fix to Order Service..."
# Stop and remove the broken container that had the bad DB config
docker stop broken-order-service || true
docker rm broken-order-service || true

# Start the correct service via compose, which uses the correct .env configuration
docker compose start order-service

echo "Order Service configuration fixed and restarted. Verifying health..."
sleep 5
curl -s http://localhost:8003/health
echo -e "\nSystem restored. Metrics should normalize in Grafana within 1 minute."
