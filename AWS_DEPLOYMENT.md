# AWS EC2 Deployment Guide for Todo App

## Prerequisites

- AWS Account with EC2 access
- An EC2 key pair (for SSH access)
- EC2 instance launched with one of these AMIs:
  - Amazon Linux 2
  - Ubuntu 22.04 LTS (recommended)
  - Debian 12

## Step 1: Launch an EC2 Instance

### 1.1 In the AWS Console:

1. Go to EC2 Dashboard → Instances → Launch Instances
2. **Name**: `todo-app`
3. **AMI**: Select `Ubuntu Server 22.04 LTS` (or Amazon Linux 2)
4. **Instance Type**: `t3.small` or larger (for production, use `t3.medium`)
5. **Storage**: 30 GB gp3 (sufficient for app + database)
6. **Security Group**: Create a new security group with these rules:
   - SSH (22): from your IP or 0.0.0.0/0 (for testing only)
   - HTTP (80): from 0.0.0.0/0
   - HTTPS (443): from 0.0.0.0/0 (optional, if adding SSL)

7. **Key Pair**: Select or create a new one (e.g., `todo-app-key.pem`)
8. Launch the instance

### 1.2 Get the Public IP

Once running, note the **Public IPv4 address** (e.g., `54.123.45.67`)

## Step 2: SSH into the Instance

```bash
chmod 600 /path/to/todo-app-key.pem
ssh -i /path/to/todo-app-key.pem ubuntu@54.123.45.67
# Or for Amazon Linux 2: ec2-user@54.123.45.67
```

## Step 3: Deploy the Application

### Option A: Automated Deployment (Recommended)

```bash
# Option 1: From a local shell script
bash deploy.sh

# Option 2: Download and run from GitHub
curl -fsSL https://raw.githubusercontent.com/<your-org>/todo-app/main/deploy.sh | bash
```

### Option B: Manual Deployment

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker and Docker Compose
sudo apt-get install -y docker.io docker-compose-plugin git curl

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Clone your repository
cd /opt
sudo mkdir -p todo-app
sudo chown $USER:docker todo-app
cd todo-app
git clone https://github.com/<your-org>/todo-app .

# Create .env file
cat > .env << 'EOF'
MYSQL_PASSWORD=secret
MYSQL_DB=todos
DOMAIN=54.123.45.67  # Replace with your EC2 public IP
EOF

# Build and start services
docker compose -f compose.prod.yaml build
docker compose -f compose.prod.yaml up -d

# View logs
docker compose -f compose.prod.yaml logs -f
```

## Step 4: Access the Application

Once deployment is complete:

### Via IP Address
```
Frontend:   http://54.123.45.67
API:        http://54.123.45.67/api
phpMyAdmin: http://db.54.123.45.67
```

### Via Domain Name (Optional)

If you own a domain, update DNS records:

```
todo-app.example.com     A  54.123.45.67
db.todo-app.example.com  A  54.123.45.67
```

Then update `.env`:
```
DOMAIN=todo-app.example.com
```

Redeploy:
```bash
docker compose -f compose.prod.yaml up -d
```

## Step 5: Maintenance & Monitoring

### View Logs
```bash
docker compose -f compose.prod.yaml logs -f

# Follow a specific service
docker compose -f compose.prod.yaml logs -f backend
docker compose -f compose.prod.yaml logs -f mysql
```

### View Running Containers
```bash
docker ps
```

### Stop Services
```bash
docker compose -f compose.prod.yaml down
```

### Restart Services
```bash
docker compose -f compose.prod.yaml restart
```

### Update and Redeploy
```bash
cd /opt/todo-app
git pull origin main
docker compose -f compose.prod.yaml down
docker compose -f compose.prod.yaml build --no-cache
docker compose -f compose.prod.yaml up -d
```

### Check Disk Usage
```bash
docker system df

# Clean up unused images/volumes
docker system prune -a
```

## Step 6: Database Backup

### Backup MySQL Data
```bash
docker exec getting-started-todo-app-mysql-1 mysqldump -u root -psecret todos > backup.sql
```

### Restore from Backup
```bash
docker exec -i getting-started-todo-app-mysql-1 mysql -u root -psecret todos < backup.sql
```

## Step 7: SSL/HTTPS with Let's Encrypt (Optional)

To secure your application with HTTPS:

### Install Certbot
```bash
sudo apt-get install -y certbot python3-certbot-nginx
```

### Request a Certificate
```bash
sudo certbot certonly --standalone -d todo-app.example.com -d db.todo-app.example.com
```

### Configure Traefik for HTTPS

Update `compose.prod.yaml` to include HTTPS support (requires Traefik configuration file).

## Troubleshooting

### Services won't start
```bash
docker compose -f compose.prod.yaml logs
docker ps -a
```

### Database connection fails
```bash
docker compose -f compose.prod.yaml exec mysql mysql -u root -psecret todos -e "SELECT 1;"
```

### Out of disk space
```bash
sudo df -h
docker system prune -a --volumes
```

### Port 80 already in use
```bash
sudo netstat -tlnp | grep :80
# Kill the process using port 80
sudo kill <PID>
```

## Production Recommendations

1. **Change MySQL password** in `.env` (use a strong password)
2. **Use AWS RDS** instead of containerized MySQL for easier backups and scaling
3. **Set up SSL/HTTPS** with Let's Encrypt or AWS Certificate Manager
4. **Enable CloudWatch monitoring** for logs and metrics
5. **Set up auto-scaling** with load balancer for high availability
6. **Use AWS Secrets Manager** for sensitive credentials
7. **Enable VPC security groups** to restrict traffic
8. **Set up regular backups** with AWS Backup or EBS snapshots
9. **Monitor costs** with AWS Cost Explorer
10. **Use CloudFront CDN** for static content caching

## Next Steps

- Add a domain name and SSL certificate
- Set up automated backups
- Configure monitoring and alerts
- Plan for scaling (RDS, ECS, Kubernetes)
