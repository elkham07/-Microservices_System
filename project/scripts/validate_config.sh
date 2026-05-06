#!/bin/bash
# scripts/validate_config.sh
# Validation of environment variables before deployment (Assignment 6 - 4.5)

echo "--- Starting Pre-deployment Configuration Validation ---"

# 1. Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file is missing!"
    exit 1
fi

# 2. Check for required variables
REQUIRED_VARS=("POSTGRES_USER" "POSTGRES_PASSWORD" "DB_HOST" "DB_PORT" "AUTH_DB" "PRODUCT_DB" "ORDER_DB" "USER_DB" "CHAT_DB")
MISSING=0

for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^$var=" .env; then
        echo "Error: Variable $var is missing in .env"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo "Validation FAILED. Please check your .env file."
    exit 1
fi

echo "All required environment variables are present."

# 3. Validate template-based configuration (docker-compose)
if ! docker-compose config > /dev/null; then
    echo "Error: docker-compose.yml has syntax errors or missing variables!"
    exit 1
fi

echo "Docker Compose configuration is valid."
echo "--- Pre-deployment Validation SUCCESSFUL ---"
