from fastapi import FastAPI, HTTPException, Depends, Request
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import os
import datetime
import time
import random

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@postgres:5432/paymentdb")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Metrics
HTTP_REQUESTS_TOTAL = Counter("payment_http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"])
HTTP_REQUEST_DURATION = Histogram("payment_http_request_duration_seconds", "HTTP request duration")
PAYMENTS_PROCESSED_TOTAL = Counter("payments_processed_total", "Total payments processed", ["status"])

app = FastAPI(title="Payment Service")

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    HTTP_REQUESTS_TOTAL.labels(method=request.method, endpoint=request.url.path, status=response.status_code).inc()
    HTTP_REQUEST_DURATION.observe(duration)
    return response

class Payment(Base):
    __tablename__ = "payments"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer)
    amount = Column(Float)
    status = Column(String) # SUCCESS, FAILED
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

Base.metadata.create_all(bind=engine)

class PaymentRequest(BaseModel):
    order_id: int
    amount: float

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()

@app.get("/health")
def health(): return {"status": "ok", "service": "payment"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/pay")
def process_payment(req: PaymentRequest, db: Session = Depends(get_db)):
    # Simulate payment processing logic
    status = "SUCCESS" if random.random() > 0.05 else "FAILED"
    payment = Payment(order_id=req.order_id, amount=req.amount, status=status)
    db.add(payment)
    db.commit()
    PAYMENTS_PROCESSED_TOTAL.labels(status=status).inc()
    
    if status == "FAILED":
        raise HTTPException(status_code=400, detail="Payment failed")
    
    return {"payment_id": payment.id, "status": status}
