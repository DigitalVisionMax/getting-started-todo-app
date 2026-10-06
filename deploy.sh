#!/bin/bash
###################################################
# EC2 Deployment Script for Todo App
#
# This script automates Docker and Docker Compose setup on a fresh EC2 instance.
# It installs Docker, pulls the application code, and starts the services.
#
# Usage:
#   1. Launch an EC2 instance (Amazon Linux 2, Ubuntu 22.04 LTS, or similar)
#   2. SSH into the instance
#   3. Run: curl -fsSL https://your-domain.com/deploy.sh | bash
#      OR upload this script and run: bash deploy.sh
###################################################

set -e

echo "========================================"
echo "Todo App EC2 Deployment"
echo "========================================"

# Detect OS and install Docker
echo "Step 1: Installing Docker..."
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose-plugin git curl
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker
elif command -v yum &> /dev/null; then
    # Amazon Linux / CentOS / RHEL
    sudo yum update -y
    sudo yum install -y docker git curl
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Install Docker Compose separately on Amazon Linux
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Error: Unsupported OS. Please use Ubuntu, Debian, Amazon Linux, or CentOS."
    exit 1
fi

# Apply group change without requiring logout/login
newgrp docker << EOF

echo "Step 2: Creating application directory..."
cd /opt
if [ ! -d "todo-app" ]; then
    sudo mkdir -p /opt/todo-app
    sudo chown $USER:docker /opt/todo-app
fi
cd /opt/todo-app

echo "Step 3: Cloning application repository..."
if [ -d ".git" ]; then
    git pull origin main
else
    # Clone from GitHub (replace with your repo)
    # For now, we'll assume the repo is already available or we copy files manually
    echo "Note: Please ensure your repository is available at /opt/todo-app"
    echo "You can clone it manually or update this script with your Git URL."
fi

echo "Step 4: Creating .env file..."
cat > .env << 'ENVFILE'
MYSQL_PASSWORD=secret
MYSQL_DB=todos
DOMAIN=localhost
ENVFILE

echo "Step 5: Building Docker images..."
docker compose -f compose.prod.yaml build

echo "Step 6: Starting services..."
docker compose -f compose.prod.yaml up -d

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Services are now running:"
echo "  - Frontend:   http://<your-ec2-ip>"
echo "  - API:        http://<your-ec2-ip>/api"
echo "  - phpMyAdmin: http://db.<your-ec2-ip>"
echo ""
echo "View logs: docker compose -f compose.prod.yaml logs -f"
echo "Stop services: docker compose -f compose.prod.yaml down"
echo ""

EOF
