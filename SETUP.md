# Setup Guide

Complete setup instructions for the Events Management API.

## Prerequisites Installation

### 1. AWS CLI

**macOS:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify:**
```bash
aws --version
```

### 2. Node.js and npm

**macOS:**
```bash
brew install node
```

**Linux:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Verify:**
```bash
node --version  # Should be 18+
npm --version
```

### 3. Python 3.12+

**macOS:**
```bash
brew install python@3.12
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install python3.12 python3-pip
```

**Verify:**
```bash
python3 --version
```

### 4. Docker

**macOS:**
- Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Start Docker Desktop

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl start docker
```

**Verify:**
```bash
docker info
```

### 5. AWS CDK

```bash
npm install -g aws-cdk
```

**Verify:**
```bash
cdk --version
```

## AWS Configuration

### 1. Create AWS Account

If you don't have one: https://aws.amazon.com/

### 2. Create IAM User

1. Go to AWS Console → IAM
2. Create new user with programmatic access
3. Attach policies:
   - `AWSLambdaFullAccess`
   - `AmazonAPIGatewayAdministrator`
   - `AmazonDynamoDBFullAccess`
   - `CloudFormationFullAccess`
   - `IAMFullAccess`

4. Save Access Key ID and Secret Access Key

### 3. Configure AWS CLI

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-west-2`)
- Default output format: `json`

**Verify:**
```bash
aws sts get-caller-identity
```

## Project Setup

### 1. Clone/Download Project

```bash
cd /path/to/project
```

### 2. Make Scripts Executable

```bash
chmod +x deploy.sh test_api.sh
```

### 3. Install Infrastructure Dependencies

```bash
cd infrastructure
npm install
cd ..
```

## Deployment

### 1. Bootstrap CDK (First Time Only)

```bash
cd infrastructure
cdk bootstrap
cd ..
```

### 2. Deploy

```bash
./deploy.sh
```

This will:
- ✅ Check all prerequisites
- ✅ Install dependencies
- ✅ Build infrastructure
- ✅ Deploy to AWS (~5 minutes)
- ✅ Output your API URL

### 3. Save Your API URL

The deployment will output something like:
```
InfrastructureStack.ApiUrl = https://abc123.execute-api.us-west-2.amazonaws.com/prod/
```

Save this URL!

## Testing

### 1. Run Test Suite

```bash
./test_api.sh https://YOUR-API-URL/prod
```

### 2. Manual Testing

```bash
# Health check
curl https://YOUR-API-URL/prod/health

# Create event
curl -X POST https://YOUR-API-URL/prod/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Event",
    "description": "Testing the API",
    "date": "2025-12-25",
    "location": "Online",
    "capacity": 100,
    "organizer": "Me",
    "status": "active"
  }'

# List events
curl https://YOUR-API-URL/prod/events
```

### 3. Interactive Documentation

Visit in your browser:
- Swagger UI: `https://YOUR-API-URL/prod/docs`
- ReDoc: `https://YOUR-API-URL/prod/redoc`

## Local Development Setup

### 1. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Set Environment Variable

```bash
export EVENTS_TABLE_NAME=EventsTable
```

### 3. Run Locally

```bash
uvicorn main:app --reload
```

Visit http://localhost:8000/docs

## Troubleshooting

### Docker Not Running

**Error:** `Cannot connect to the Docker daemon`

**Solution:**
```bash
# macOS: Start Docker Desktop
# Linux:
sudo systemctl start docker
docker info
```

### AWS Credentials Not Configured

**Error:** `Unable to locate credentials`

**Solution:**
```bash
aws configure
# Enter your credentials
```

### CDK Bootstrap Error

**Error:** `This stack uses assets, so the toolkit stack must be deployed`

**Solution:**
```bash
cd infrastructure
cdk bootstrap aws://ACCOUNT-ID/REGION
```

### Node.js Version Too Old

**Error:** `Node.js version must be >= 18`

**Solution:**
```bash
# macOS
brew upgrade node

# Linux
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Python Dependencies Installation Fails

**Solution:**
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r backend/requirements.txt
```

## Cleanup

### Remove All AWS Resources

```bash
cd infrastructure
cdk destroy
```

Confirm when prompted. This will delete:
- Lambda function
- API Gateway
- DynamoDB table (and all data!)
- IAM roles
- CloudWatch logs

## Next Steps

1. ✅ Review the [API Documentation](backend/docs/index.html)
2. ✅ Read the [Backend README](backend/README.md)
3. ✅ Check the [Infrastructure README](infrastructure/README.md)
4. ✅ Explore the interactive docs at `/docs`

## Support

For issues:
1. Check CloudWatch logs
2. Review error messages
3. Verify AWS service quotas
4. Test locally first

## Production Checklist

Before going to production:

- [ ] Add API authentication
- [ ] Restrict CORS to specific origins
- [ ] Enable AWS WAF
- [ ] Set up monitoring and alerts
- [ ] Configure automated backups
- [ ] Review and adjust rate limits
- [ ] Set up CI/CD pipeline
- [ ] Enable CloudTrail logging
- [ ] Configure custom domain
- [ ] Set up staging environment
