#!/bin/bash

# 1. Python main files
cat << 'INNER_EOF' > product-service/main.py
from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/productdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
REQUEST_COUNT = Counter("product_requests_total", "Total requests", ["method", "endpoint", "status"])

app = FastAPI(title="Product Service")

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    price = Column(Float)

Base.metadata.create_all(bind=engine)

@app.get("/health")
def health(): return {"status": "ok", "service": "product"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
INNER_EOF

cat << 'INNER_EOF' > order-service/main.py
from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/orderdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
REQUEST_COUNT = Counter("order_requests_total", "Total requests", ["method", "endpoint", "status"])

app = FastAPI(title="Order Service")

class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer)
    status = Column(String, default="pending")

Base.metadata.create_all(bind=engine)

@app.get("/health")
def health(): return {"status": "ok", "service": "order"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
INNER_EOF

cat << 'INNER_EOF' > user-service/main.py
from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/userdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
REQUEST_COUNT = Counter("user_requests_total", "Total requests", ["method", "endpoint", "status"])

app = FastAPI(title="User Service")

class UserProfile(Base):
    __tablename__ = "profiles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True)
    full_name = Column(String)

Base.metadata.create_all(bind=engine)

@app.get("/health")
def health(): return {"status": "ok", "service": "user"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
INNER_EOF

cat << 'INNER_EOF' > chat-service/main.py
from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/chatdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
REQUEST_COUNT = Counter("chat_requests_total", "Total requests", ["method", "endpoint", "status"])

app = FastAPI(title="Chat Service")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    content = Column(String)

Base.metadata.create_all(bind=engine)

@app.get("/health")
def health(): return {"status": "ok", "service": "chat"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
INNER_EOF

# 2. Requirements and Dockerfiles
cat << 'INNER_EOF' > requirements.txt
fastapi==0.103.1
uvicorn==0.23.2
sqlalchemy==2.0.20
psycopg2-binary==2.9.7
prometheus-client==0.17.1
pydantic==2.3.0
INNER_EOF

ports=("auth-service:8001" "product-service:8002" "order-service:8003" "user-service:8004" "chat-service:8005")

for entry in "${ports[@]}"; do
    service="${entry%%:*}"
    port="${entry##*:}"
    cp requirements.txt $service/
    cat << INNER_EOF > $service/Dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "$port"]
INNER_EOF
done

# Frontend Dockerfile
cat << 'INNER_EOF' > frontend/Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
INNER_EOF

# 3. DB Init
cat << 'INNER_EOF' > init-db.sh
#!/bin/bash
set -e
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
  for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
      CREATE DATABASE $db;
EOSQL
  done
fi
INNER_EOF
chmod +x init-db.sh

# 4. Monitoring Configs
mkdir -p monitoring/grafana/provisioning/datasources
cat << 'INNER_EOF' > monitoring/prometheus.yml
global:
  scrape_interval: 5s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'services'
    static_configs:
      - targets: 
        - 'auth-service:8001'
        - 'product-service:8002'
        - 'order-service:8003'
        - 'user-service:8004'
        - 'chat-service:8005'
INNER_EOF

cat << 'INNER_EOF' > monitoring/grafana/provisioning/datasources/datasource.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
INNER_EOF

# 5. Terraform files
cat << 'INNER_EOF' > terraform/main.tf
provider "aws" {
  region = var.region
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "Microservices-App-Server"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow required ports"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
INNER_EOF

cat << 'INNER_EOF' > terraform/variables.tf
variable "region" {
  default = "us-east-1"
}
variable "instance_type" {
  default = "t2.micro"
}
INNER_EOF

cat << 'INNER_EOF' > terraform/outputs.tf
output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}
INNER_EOF

cat << 'INNER_EOF' > terraform/terraform.tfvars
region = "us-east-1"
instance_type = "t2.micro"
INNER_EOF

