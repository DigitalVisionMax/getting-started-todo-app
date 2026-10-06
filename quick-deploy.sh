#!/bin/bash
###################################################
# Quick AWS EC2 Deployment - Manual Setup
#
# This is a condensed version for experienced users.
# Run this after SSHing into a fresh EC2 instance.
###################################################

set -e

# Install Docker
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin git

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker << 'EOF'

# Clone and deploy
cd /opt
sudo mkdir -p todo-app
sudo chown $USER:docker todo-app
cd todo-app

# Clone your repo (or copy files manually)
git clone https://github.com/<YOUR-ORG>/todo-app .

# Create .env
cat > .env << 'ENVFILE'
MYSQL_PASSWORD=secret
MYSQL_DB=todos
DOMAIN=localhost
ENVFILE

# Build and run
docker compose -f compose.prod.yaml build
docker compose -f compose.prod.yaml up -d

echo "Done! App is running at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

EOF
