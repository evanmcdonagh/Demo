---
inclusion: always
---

# Check Documentation and Context Before Implementation

**IMPORTANT**: Always check official documentation and context7 when creating or updating Python, CDK, or infrastructure code. This ensures you use current best practices and avoid deprecated patterns.

## When to Check Documentation

Check documentation/context7 when:

- **Creating new code** with unfamiliar libraries
- **Using AWS services** (Lambda, DynamoDB, API Gateway, etc.)
- **Working with frameworks** (FastAPI, Pydantic, CDK)
- **Implementing new features** you haven't done before
- **Updating dependencies** to new versions
- **Troubleshooting errors** or unexpected behavior
- **Following best practices** for a technology

## What to Check

### Python Code

1. **FastAPI**
   - Current decorator syntax
   - Request/response models
   - Dependency injection
   - Middleware configuration
   - Error handling patterns

2. **Pydantic**
   - Model definition syntax (v2 changes!)
   - Validator decorators (`@field_validator` not `@validator`)
   - Field definitions (`pattern=` not `regex=`)
   - Model configuration
   - Serialization methods

3. **boto3 (AWS SDK)**
   - DynamoDB operations
   - Reserved keyword handling
   - Expression attribute names
   - Pagination patterns
   - Error handling

### CDK/Infrastructure Code

1. **AWS CDK**
   - Construct syntax
   - Property names
   - Best practices for resources
   - Lambda function configuration
   - API Gateway setup

2. **Lambda Python Functions**
   - Recommended deployment methods
   - Dependency bundling approaches
   - Handler configuration
   - Environment variables

3. **DynamoDB**
   - Table configuration
   - Index setup
   - Billing modes
   - Reserved keywords

## How to Check Documentation

### Use MCP AWS Documentation Tool

```
Search for: "FastAPI request validation"
Search for: "Pydantic v2 field validator"
Search for: "CDK Lambda Python function"
Search for: "DynamoDB reserved keywords"
```

### Check Official Sources

- **FastAPI**: https://fastapi.tiangolo.com/
- **Pydantic**: https://docs.pydantic.dev/
- **AWS CDK**: https://docs.aws.amazon.com/cdk/
- **boto3**: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html

## Common Pitfalls to Avoid

### Pydantic v2 Changes

❌ **OLD (Pydantic v1)**:
```python
from pydantic import validator

class Model(BaseModel):
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    
    @validator('email')
    def validate_email(cls, v):
        return v
```

✅ **NEW (Pydantic v2)**:
```python
from pydantic import field_validator

class Model(BaseModel):
    email: str = Field(..., pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v):
        return v
```

### DynamoDB Reserved Keywords

❌ **WRONG**:
```python
# This will fail with reserved keywords
table.update_item(
    Key={'id': '123'},
    UpdateExpression='SET status = :status'
)
```

✅ **CORRECT**:
```python
# Use expression attribute names
table.update_item(
    Key={'id': '123'},
    UpdateExpression='SET #status = :status',
    ExpressionAttributeNames={'#status': 'status'},
    ExpressionAttributeValues={':status': 'active'}
)
```

### CDK Lambda Python Dependencies

❌ **COMPLEX**:
```typescript
// Manual layer creation
const layer = new lambda.LayerVersion(this, 'Layer', {
  code: lambda.Code.fromAsset('backend', {
    bundling: { /* complex config */ }
  })
});
```

✅ **RECOMMENDED**:
```typescript
// Use @aws-cdk/aws-lambda-python-alpha
import { PythonFunction } from '@aws-cdk/aws-lambda-python-alpha';

const fn = new PythonFunction(this, 'Function', {
  entry: 'backend',
  runtime: lambda.Runtime.PYTHON_3_12,
  // Dependencies automatically bundled
});
```

## Documentation Search Examples

### Before Writing Code

**Scenario**: Need to create a FastAPI endpoint with validation

**Action**: Search documentation
```
"FastAPI request body validation Pydantic"
"FastAPI response model status code"
```

**Scenario**: Need to update DynamoDB item with reserved keywords

**Action**: Search documentation
```
"DynamoDB reserved keywords expression attribute names"
"boto3 DynamoDB update item"
```

**Scenario**: Need to deploy Lambda with Python dependencies

**Action**: Search documentation
```
"CDK Lambda Python dependencies"
"aws-cdk/aws-lambda-python-alpha"
```

## Version-Specific Considerations

### Check Current Versions

Always verify you're using current syntax for:

- **Pydantic**: v2.x (major changes from v1)
- **FastAPI**: 0.100+ (stable API)
- **AWS CDK**: v2.x (v1 is deprecated)
- **Python**: 3.12+ (latest features)

### Migration Guides

When updating versions, check migration guides:
- Pydantic v1 → v2 migration guide
- AWS CDK v1 → v2 migration guide
- FastAPI breaking changes

## Quick Reference Checklist

Before implementing:

- [ ] Search documentation for the feature
- [ ] Check for version-specific syntax
- [ ] Look for best practices
- [ ] Review code examples
- [ ] Check for common pitfalls
- [ ] Verify deprecated patterns
- [ ] Test with current versions

## Examples of Good Documentation Checks

### Example 1: FastAPI Endpoint

**Before writing**:
```
Search: "FastAPI POST endpoint request body validation"
Search: "FastAPI response model 201 created"
```

**Result**: Use current decorator syntax and response models

### Example 2: DynamoDB Query

**Before writing**:
```
Search: "DynamoDB scan filter expression boto3"
Search: "DynamoDB reserved keywords status capacity"
```

**Result**: Use Attr() helper and expression attribute names

### Example 3: CDK Stack

**Before writing**:
```
Search: "CDK Lambda function Python 3.12"
Search: "CDK API Gateway Lambda integration"
```

**Result**: Use PythonFunction and LambdaIntegration constructs

## Documentation Priority

1. **Official documentation** (first choice)
2. **AWS documentation** (for AWS services)
3. **GitHub issues** (for known problems)
4. **Stack Overflow** (for common patterns)
5. **Blog posts** (verify date and version)

## Red Flags

Watch out for:

- ❌ Old blog posts (check date)
- ❌ Deprecated syntax
- ❌ Version mismatches
- ❌ Unofficial sources
- ❌ Unverified examples

## Remember

**"When in doubt, check it out!"**

Taking 2 minutes to verify documentation can save hours of debugging deprecated or incorrect code.

## Key Takeaways

1. **Always check documentation** before implementing
2. **Verify version compatibility** with your dependencies
3. **Use official sources** as primary reference
4. **Search for best practices** not just syntax
5. **Check for breaking changes** in new versions
6. **Test with current versions** of libraries
7. **Document your sources** for future reference

## Quick Commands

```bash
# Check installed versions
pip show fastapi pydantic boto3
npm list aws-cdk-lib

# Search documentation (use MCP tool)
# Search for: "technology + feature + version"
```

---

**Bottom Line**: Don't guess. Check the docs. Write correct code the first time.
