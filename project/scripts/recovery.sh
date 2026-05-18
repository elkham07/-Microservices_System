#!/bin/bash
echo "Applying fix to Order Service..."

# Detect if we are using Kubernetes
if kubectl get pods -n microservices >/dev/null 2>&1; then
  echo "Detected Kubernetes environment."
  echo "Restoring correct DATABASE_URL for order-service..."
  kubectl set env deployment/order-service DATABASE_URL="postgresql://user:password@postgres:5432/orderdb" -n microservices
  echo "Order Service configuration fixed. Verifying health..."
  sleep 5
  kubectl get pods -n microservices -l app=order-service
else
  echo "Detected Docker Compose environment."
  docker stop broken-order-service || true
  docker rm broken-order-service || true
  docker compose start order-service
  echo "Order Service configuration fixed and restarted. Verifying health..."
  sleep 5
  curl -s http://localhost:8003/health
fi

echo -e "\nSystem restored. Metrics should normalize in Grafana within 1 minute."
