# SRE Capacity Planning & Automation Report

## 1. Resource Consumption Analysis
Based on simulated load tests, the following services were identified as high-resource consumers:
- **Order Service**: High CPU during peak order processing.
- **Payment Service**: High latency due to external integration simulations.
- **PostgreSQL**: Identified as a potential bottleneck when concurrent connections exceed 100.

## 2. Scaling Strategies
### Horizontal Scaling
- **Order Service**: Increased to 3 replicas in Docker Swarm and Kubernetes HPA.
- **Payment Service**: Scaled horizontally to handle increased transaction throughput.

### Vertical Scaling
- **Database**: Allocated more RAM (from 1GB to 4GB) to optimize query caching.

## 3. Automation & Reliability
- **Health Checks**: Implemented `liveness` and `readiness` probes for all K8s pods.
- **Restart Policies**: Configured `restart: unless-stopped` in Docker Compose to ensure 99.9% availability.
- **Auto-healing**: Kubernetes automatically restarts containers that fail health checks.

## 4. Load Balancing
- **Nginx**: Acts as a reverse proxy and load balancer, distributing traffic across service replicas using a Round Robin algorithm.
