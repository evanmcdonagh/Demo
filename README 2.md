# Demo

Monorepo containing a FastAPI backend and CDK infrastructure.

## Structure

- `backend/` - FastAPI REST API
- `infrastructure/` - AWS CDK TypeScript infrastructure

## Getting Started

### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### Infrastructure
```bash
cd infrastructure
npm install
npm run cdk deploy
```

