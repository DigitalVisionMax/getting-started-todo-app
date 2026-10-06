# Todo App EC2 Deployment - Quick Reference

## Launch EC2 Instance

```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.small \
  --key-name todo-app-key \
  --security-groups default \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=todo-app}]'
```

## Get Public IP

```bash
aws ec2 describe-instances --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

## SSH & Deploy

```bash
# SSH in
ssh -i todo-app-key.pem ubuntu@<PUBLIC_IP>

# Deploy (run all-in-one)
curl -fsSL https://raw.githubusercontent.com/your-org/todo-app/main/quick-deploy.sh | bash

# Or upload and run locally
scp -i todo-app-key.pem quick-deploy.sh ubuntu@<PUBLIC_IP>:~/
ssh -i todo-app-key.pem ubuntu@<PUBLIC_IP> bash quick-deploy.sh
```

## Monitor

```bash
# SSH back in
ssh -i todo-app-key.pem ubuntu@<PUBLIC_IP>

# Check logs
docker compose -f /opt/todo-app/compose.prod.yaml logs -f

# Check services
docker ps
```

## Update Domain in .env (Optional)

```bash
ssh -i todo-app-key.pem ubuntu@<PUBLIC_IP>
nano /opt/todo-app/.env
# Change DOMAIN=<YOUR_DOMAIN_OR_IP>
docker compose -f /opt/todo-app/compose.prod.yaml restart proxy
```

## Cleanup

```bash
# Delete instance
aws ec2 terminate-instances --instance-ids <INSTANCE_ID>
```

## Costs

For `t3.small` instance (~30GB storage):
- Compute: ~$0.022/hour (varies by region)
- Storage: ~$3/month (30GB gp3)
- Data transfer: ~$0.09/GB out
- **Total**: ~$30-40/month (light usage)

For better uptime use `t3.medium` or leverage AWS RDS for MySQL (~$15-30/month).
