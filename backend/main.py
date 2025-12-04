"""FastAPI application entry point."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

from backend.routes import events, users, registrations


app = FastAPI(title="Events API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoints
@app.get("/")
def read_root():
    return {"message": "Events API is running", "version": "1.0.0"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


# Include routers
app.include_router(events.router)
app.include_router(users.router)
app.include_router(registrations.router)

# Lambda handler
handler = Mangum(app)
