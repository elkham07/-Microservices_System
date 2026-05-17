#!/bin/bash
mkdir -p project/k8s

services=(
  "product-service:8002:productdb"
  "order-service:8003:orderdb"
  "user-service:8004:userdb"
  "chat-service:8005:chatdb"
  "payment-service:8006:paymentdb"
  "notification-service:8007:notificationdb"
)

for svc in "${services[@]}"; do
  IFS=":" read -r name port dbname <<< "$svc"
  cat << YAML > "project/k8s/${name}-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${name}
  template:
    metadata:
      labels:
        app: ${name}
    spec:
      containers:
      - name: ${name}
        image: ${name}:latest
        ports:
        - containerPort: ${port}
        env:
        - name: DATABASE_URL
          value: "postgresql://user:password@postgres:5432/${dbname}"
        livenessProbe:
          httpGet:
            path: /health
            port: ${port}
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ${name}
  namespace: microservices
spec:
  selector:
    app: ${name}
  ports:
    - protocol: TCP
      port: ${port}
      targetPort: ${port}
  type: ClusterIP
YAML
done

cat << YAML > "project/k8s/postgres-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: "user"
        - name: POSTGRES_PASSWORD
          value: "password"
        - name: POSTGRES_MULTIPLE_DATABASES
          value: "authdb,productdb,orderdb,userdb,chatdb,paymentdb,notificationdb"
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: microservices
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  type: ClusterIP
YAML

cat << YAML > "project/k8s/redis-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: microservices
spec:
  selector:
    app: redis
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379
  type: ClusterIP
YAML

cat << YAML > "project/k8s/frontend-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: microservices
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: frontend:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: microservices
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
YAML

cat << YAML > "project/k8s/monitoring-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: microservices
spec:
  selector:
    app: prometheus
  ports:
    - protocol: TCP
      port: 9090
      targetPort: 9090
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: microservices
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: microservices
spec:
  selector:
    app: grafana
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
  type: NodePort
YAML

