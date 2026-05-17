#!/bin/bash
echo "Simulating incident: Breaking Order Service DB connection..."
# We can simulate this by stopping the DB or changing the env var of the order service
# For demonstration, we'll just stop the order-service and show the alert in Prometheus
docker compose stop order-service
echo "Order Service is DOWN. Check Grafana/Prometheus for alerts."
sleep 10
echo "Incident in progress. SRE team notified (via Alertmanager)."
