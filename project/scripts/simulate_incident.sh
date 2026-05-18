#!/bin/bash
echo "Simulating incident: Breaking Order Service DB connection..."

# To simulate a database configuration error, we will manually stop the order service
# and start a broken version with an invalid DATABASE_URL.
echo "Modifying DATABASE_URL for order-service to point to an invalid host..."
docker compose stop order-service
docker run -d --name broken-order-service -e DATABASE_URL="postgresql://user:password@invalid-db-host:5432/orderdb" -p 8003:8003 order-service:latest

echo "Order Service is now running with an INCORRECT database configuration."
echo "Check Grafana/Prometheus for HighErrorRate and ServiceDown alerts."
sleep 5
echo "Incident in progress. SRE team notified (via Alertmanager)."
