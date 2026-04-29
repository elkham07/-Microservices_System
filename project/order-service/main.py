from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/orderdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
REQUEST_COUNT = Counter("order_requests_total", "Total requests", ["method", "endpoint", "status"])

app = FastAPI(title="Order Service")

class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer)
    status = Column(String, default="pending")

Base.metadata.create_all(bind=engine)

@app.get("/health")
def health(): return {"status": "ok", "service": "order"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
