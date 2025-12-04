#!/bin/bash

# Events API Deployment Script

echo "========================================="
echo "Events API Deployment"
echo "========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    echo "Please install AWS CLI from https://aws.amazon.com/cli/"
    exit 1
fi

if ! command -v cdk &> /dev/null; then
    echo "⚠️  AWS CDK is not installed globally"
    echo "Installing AWS CDK..."
    npm install -g aws-cdk
fi

echo "✅ All prerequisites met"
echo ""

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS credentials configured"
echo ""

# Install infrastructure dependencies
echo "Installing infrastructure dependencies..."
cd infrastructure
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

# Check for Docker (required for PythonFunction bundling)
echo "Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "⚠️  Docker is not running or not installed"
    echo "Docker is required for bundling Python dependencies"
    echo "Please start Docker and try again"
    exit 1
fi
if ! docker info &> /dev/null; then
    echo "⚠️  Docker daemon is not running"
    echo "Please start Docker and try again"
    exit 1
fi
echo "✅ Docker is running"
echo ""

# Build TypeScript
echo "Building TypeScript..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi
echo "✅ Build successful"
echo ""

# Bootstrap CDK (if needed)
echo "Checking CDK bootstrap..."
cdk bootstrap
echo ""

# Deploy
echo "Deploying to AWS..."
echo "This may take several minutes..."
cdk deploy --require-approval never

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✅ Deployment successful!"
    echo "========================================="
    echo ""
    echo "Your API is now live. Check the output above for the API URL."
    echo ""
    echo "Test your API:"
    echo "  curl https://YOUR-API-URL/prod/health"
    echo ""
else
    echo ""
    echo "❌ Deployment failed"
    exit 1
fi
