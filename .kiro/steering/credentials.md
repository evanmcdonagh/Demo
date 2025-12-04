---
inclusion: always
---

# Credentials and Sensitive Information Handling

**IMPORTANT**: Always prompt the user for credentials and sensitive information. Never assume, hardcode, or expose credentials in code or documentation.

## When to Prompt for Credentials

Prompt the user when you need:

- **AWS Credentials**
  - AWS Access Key ID
  - AWS Secret Access Key
  - AWS Region
  - AWS Account ID

- **API Keys**
  - Third-party service API keys
  - Authentication tokens
  - Service credentials

- **Database Credentials**
  - Database passwords
  - Connection strings with credentials
  - Database user credentials

- **Secrets and Tokens**
  - JWT secrets
  - Encryption keys
  - OAuth client secrets
  - Webhook secrets

## How to Handle Credentials

### ✅ DO

1. **Prompt the user** before using any credentials:
   ```
   "I need your AWS credentials to deploy. Please run:
   aws configure
   
   Or provide your:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region"
   ```

2. **Use environment variables**:
   ```python
   import os
   api_key = os.environ.get('API_KEY')
   ```

3. **Reference credential files**:
   ```python
   # Use AWS credentials from ~/.aws/credentials
   # Use .env files for local development
   ```

4. **Use AWS Secrets Manager or Parameter Store**:
   ```python
   # For production secrets
   secret = boto3.client('secretsmanager').get_secret_value(SecretId='my-secret')
   ```

5. **Check if credentials are configured**:
   ```bash
   aws sts get-caller-identity  # Verify AWS credentials
   ```

### ❌ DON'T

1. **Never hardcode credentials**:
   ```python
   # ❌ NEVER DO THIS
   api_key = "sk-1234567890abcdef"
   aws_access_key = "AKIAIOSFODNN7EXAMPLE"
   ```

2. **Never commit credentials to git**:
   - Add `.env` to `.gitignore`
   - Add credential files to `.gitignore`
   - Never commit AWS credentials

3. **Never log credentials**:
   ```python
   # ❌ NEVER DO THIS
   print(f"Using API key: {api_key}")
   logger.info(f"AWS Secret: {secret}")
   ```

4. **Never expose credentials in error messages**:
   ```python
   # ❌ NEVER DO THIS
   raise Exception(f"Failed to connect with password: {password}")
   ```

5. **Never include credentials in documentation**:
   - Use placeholders: `YOUR-API-KEY`, `YOUR-AWS-REGION`
   - Never show real credentials in examples

## Credential Prompting Examples

### Example 1: AWS Deployment

```
Before deploying, I need to verify your AWS credentials are configured.

Please ensure you have:
1. AWS CLI installed
2. Credentials configured via: aws configure

Or set environment variables:
export AWS_ACCESS_KEY_ID=your-key-id
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-west-2

Would you like me to proceed with the deployment?
```

### Example 2: API Key Needed

```
This integration requires an API key from [Service Name].

Please:
1. Get your API key from: https://service.com/api-keys
2. Set it as an environment variable:
   export SERVICE_API_KEY=your-api-key

Or add it to your .env file:
   SERVICE_API_KEY=your-api-key

Have you configured the API key?
```

### Example 3: Database Connection

```
To connect to the database, I need credentials.

Please provide:
1. Database host
2. Database name
3. Database user

For the password, please set it as an environment variable:
export DB_PASSWORD=your-password

This keeps your password secure and out of the code.
```

## Environment Variables

Recommend using environment variables for all sensitive data:

```bash
# .env file (add to .gitignore)
AWS_REGION=us-west-2
DATABASE_URL=postgresql://user@localhost/db
API_KEY=your-api-key-here
SECRET_KEY=your-secret-key-here
```

Load in code:
```python
from dotenv import load_dotenv
import os

load_dotenv()
api_key = os.getenv('API_KEY')
```

## AWS Credentials Best Practices

1. **Use AWS CLI configuration**:
   ```bash
   aws configure
   ```

2. **Use IAM roles** (for EC2, Lambda, ECS):
   - No credentials needed in code
   - Automatically rotated
   - Scoped permissions

3. **Use AWS profiles**:
   ```bash
   aws configure --profile myproject
   export AWS_PROFILE=myproject
   ```

4. **Check credentials before operations**:
   ```bash
   aws sts get-caller-identity
   ```

## Security Reminders

- **Rotate credentials regularly**
- **Use least privilege** (minimal permissions)
- **Enable MFA** for AWS accounts
- **Monitor credential usage** (CloudTrail)
- **Revoke unused credentials**
- **Use temporary credentials** when possible

## Quick Checklist

Before writing code that uses credentials:

- [ ] Prompt user for credentials
- [ ] Use environment variables
- [ ] Never hardcode credentials
- [ ] Add credential files to .gitignore
- [ ] Document how to configure credentials
- [ ] Verify credentials are configured
- [ ] Use secure credential storage (AWS Secrets Manager)

## Remember

**When in doubt, ask the user!**

It's always better to prompt for credentials than to assume they exist or to hardcode them.
