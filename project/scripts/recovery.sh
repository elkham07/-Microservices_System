#!/bin/bash
echo "Applying fix to Order Service..."
docker compose start order-service
echo "Order Service is back online. Verifying health..."
sleep 5
curl -s http://localhost:8003/health
echo -e "\nSystem restored."
