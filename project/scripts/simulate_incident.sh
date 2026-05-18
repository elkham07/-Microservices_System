#!/bin/bash
echo "Simulating incident: Breaking Order Service DB connection..."

# Detect if we are using Kubernetes (kubectl has active pods)
if kubectl get pods -n microservices >/dev/null 2>&1; then
  echo "Detected Kubernetes environment."
  echo "Modifying DATABASE_URL for order-service in Kubernetes to point to an invalid host 'fake'..."
  kubectl set env deployment/order-service DATABASE_URL="postgresql://user:password@fake:5432/orderdb" -n microservices
  echo "Order Service in Kubernetes is now running with an INCORRECT database configuration."
  echo "Check Grafana/Prometheus for HighErrorRate and ServiceDown alerts."
else
  echo "Detected Docker Compose environment."
  echo "Modifying DATABASE_URL for order-service to point to an invalid host..."
  docker compose stop order-service
  docker run -d --name broken-order-service -e DATABASE_URL="postgresql://user:password@invalid-db-host:5432/orderdb" -p 8003:8003 order-service:latest
  echo "Order Service is now running with an INCORRECT database configuration."
  echo "Check Grafana/Prometheus for HighErrorRate and ServiceDown alerts."
fi

sleep 3
echo "Incident in progress. SRE team notified (via Alertmanager)."
