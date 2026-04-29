from fastapi import FastAPI, Depends
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/productdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
REQUEST_COUNT = Counter("product_requests_total", "Total requests", ["method", "endpoint", "status"])

app = FastAPI(title="Product Service")

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    price = Column(Float)

Base.metadata.create_all(bind=engine)

@app.get("/health")
def health(): return {"status": "ok", "service": "product"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)
