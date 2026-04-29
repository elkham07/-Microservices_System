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

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/authdb")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Prometheus metrics
REQUEST_COUNT = Counter("auth_requests_total", "Total requests", ["method", "endpoint", "status"])
REQUEST_LATENCY = Histogram("auth_request_duration_seconds", "Request latency")

app = FastAPI(title="Auth Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
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

# Schemas
class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

# Helpers
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# Routes
@app.get("/health")
def health():
    return {"status": "ok", "service": "auth"}

@app.get("/metrics")
def metrics():
    return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/register")
def register(req: RegisterRequest, db: SessionLocal = Depends(get_db)): # type: ignore
    REQUEST_COUNT.labels("POST", "/register", "200").inc()
    existing = db.query(User).filter(User.username == req.username).first()
    if existing:
        REQUEST_COUNT.labels("POST", "/register", "400").inc()
        raise HTTPException(status_code=400, detail="Username already exists")
    user = User(
        username=req.username,
        email=req.email,
        hashed_password=hash_password(req.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"id": user.id, "username": user.username, "email": user.email}

@app.post("/login")
def login(req: LoginRequest, db: SessionLocal = Depends(get_db)): # type: ignore
    user = db.query(User).filter(User.username == req.username).first()
    if not user or user.hashed_password != hash_password(req.password):
        REQUEST_COUNT.labels("POST", "/login", "401").inc()
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = str(uuid.uuid4())
    session = Session(session_token=token, user_id=user.id)
    db.add(session)
    db.commit()
    REQUEST_COUNT.labels("POST", "/login", "200").inc()
    return {"session_token": token, "user_id": user.id, "username": user.username}

@app.post("/logout")
def logout(token: str, db: SessionLocal = Depends(get_db)): # type: ignore
    session = db.query(Session).filter(Session.session_token == token).first()
    if session:
        db.delete(session)
        db.commit()
    return {"message": "Logged out"}

@app.get("/validate")
def validate_session(token: str, db: SessionLocal = Depends(get_db)): # type: ignore
    session = db.query(Session).filter(Session.session_token == token).first()
    if not session:
        raise HTTPException(status_code=401, detail="Invalid session")
    user = db.query(User).filter(User.id == session.user_id).first()
    return {"valid": True, "user_id": user.id, "username": user.username}
