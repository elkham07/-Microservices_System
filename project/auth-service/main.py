from fastapi import FastAPI, HTTPException, Depends, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import hashlib
import os
import uuid
import datetime
import time

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/authdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Standardized Metrics
HTTP_REQUESTS_TOTAL = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"])
HTTP_REQUEST_DURATION = Histogram("http_request_duration_seconds", "HTTP request duration")
SUCCESSFUL_LOGINS_TOTAL = Counter("successful_logins_total", "Total successful logins")

app = FastAPI(title="Auth Service")

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    HTTP_REQUESTS_TOTAL.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    HTTP_REQUEST_DURATION.observe(duration)
    
    return response

# Models ... (keeping existing models)
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Session(Base):
    __tablename__ = "sessions"
    id = Column(Integer, primary_key=True)
    session_token = Column(String, unique=True, index=True)
    user_id = Column(Integer)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

Base.metadata.create_all(bind=engine)

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

@app.get("/health")
def health(): return {"status": "ok", "service": "auth"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/register")
def register(req: RegisterRequest, db: SessionLocal = Depends(get_db)): # type: ignore
    user = User(username=req.username, email=req.email, hashed_password=hash_password(req.password))
    db.add(user)
    db.commit()
    return {"id": user.id}

@app.post("/login")
def login(req: LoginRequest, db: SessionLocal = Depends(get_db)): # type: ignore
    user = db.query(User).filter(User.username == req.username).first()
    if not user or user.hashed_password != hash_password(req.password):
        raise HTTPException(status_code=401)
    SUCCESSFUL_LOGINS_TOTAL.inc()
    return {"token": "mock-token"}
