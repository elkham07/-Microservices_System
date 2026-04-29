# Microservices System Deployment Documentation

## 1. Local Deployment (Docker Compose)
To deploy the entire microservices architecture locally:
1. Make sure Docker and Docker Compose are installed.
2. Run the following command in the project root:
   ```bash
   docker-compose up --build -d
   ```
3. Access the services:
   - Frontend API Gateway: http://localhost:80
   - Grafana: http://localhost:3000 (admin / admin)
   - Prometheus: http://localhost:9090

## 2. Infrastructure Deployment (Terraform)
To provision the AWS cloud infrastructure (Assignment 5):
1. Install Terraform and configure AWS CLI credentials.
2. Navigate to the `terraform` directory:
   ```bash
   cd terraform
   ```
3. Initialize Terraform (downloads providers):
   ```bash
   terraform init
   ```
4. Review the execution plan (shows what will be created):
   ```bash
   terraform plan
   ```
5. Apply the infrastructure:
   ```bash
   terraform apply -auto-approve
   ```
6. The terminal will output the `instance_public_ip`. Use this IP to access your cloud server.
