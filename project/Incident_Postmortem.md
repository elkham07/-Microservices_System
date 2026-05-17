# Incident Postmortem: Order Service Failure

**Date:** 2026-05-13
**Status:** Resolved
**Severity:** Critical

## Summary
On 2026-05-13, the Order Service became unavailable, preventing users from creating new orders. The issue was detected by Prometheus alerts within 60 seconds.

## Impact
- Users were unable to checkout or view orders.
- Estimated 5% drop in successful transactions during the 5-minute downtime.

## Root Cause
Incorrect database connection string in the environment variables after a manual configuration update. The service was unable to reach the PostgreSQL instance.

## Detection
The `ServiceDown` alert was triggered in Prometheus and visualized in the Grafana dashboard.

## Response & Resolution
1. **14:05**: Alert triggered.
2. **14:06**: SRE team investigated logs using `docker logs order-service`.
3. **14:08**: Identified the incorrect `DATABASE_URL`.
4. **14:10**: Applied the fix and restarted the service.
5. **14:11**: Verified recovery via `/health` endpoint.

## Lessons Learned
- Automate configuration changes via Ansible to prevent manual errors.
- Implement strict validation for environment variables at startup.
- Improve health check probes to catch DB connection issues earlier.
