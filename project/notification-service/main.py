from fastapi import FastAPI, Request
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response as StarletteResponse
import time
import random

app = FastAPI(title="Notification Service")

# Metrics
HTTP_REQUESTS_TOTAL = Counter("notification_http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"])
HTTP_REQUEST_DURATION = Histogram("notification_http_request_duration_seconds", "HTTP request duration")
NOTIFICATIONS_SENT_TOTAL = Counter("notifications_sent_total", "Total notifications sent", ["type"])

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    HTTP_REQUESTS_TOTAL.labels(method=request.method, endpoint=request.url.path, status=response.status_code).inc()
    HTTP_REQUEST_DURATION.observe(duration)
    return response

class NotificationRequest(BaseModel):
    user_id: int
    message: str
    type: str # EMAIL, SMS, PUSH

@app.get("/health")
def health(): return {"status": "ok", "service": "notification"}

@app.get("/metrics")
def metrics(): return StarletteResponse(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/send")
async def send_notification(req: NotificationRequest):
    # Simulate sending notification
    time.sleep(random.uniform(0.1, 0.5)) # Simulate network delay
    NOTIFICATIONS_SENT_TOTAL.labels(type=req.type).inc()
    return {"status": "sent", "type": req.type, "user_id": req.user_id}
