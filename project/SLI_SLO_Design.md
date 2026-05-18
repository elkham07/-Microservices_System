# Assignment 2: SLI/SLO Design

## Overview
This document defines the Service Level Indicators (SLIs) and Service Level Objectives (SLOs) for the distributed microservices system, focusing on ensuring high reliability and performance.

## Service Level Indicators (SLIs)
1. **Availability**: The percentage of successful requests compared to the total requests.
2. **Latency**: The time it takes to process a request and send a response.
3. **Error Rate**: The ratio of failed requests (HTTP 5xx errors) to total requests.
4. **Request Success Rate**: The percentage of requests that yield an HTTP 2xx or 3xx status code.

## Service Level Objectives (SLOs)
1. **Availability**: ≥ 99% uptime over a 30-day window.
2. **Latency**: 95th percentile latency must be ≤ 200 ms.
3. **Error Rate**: ≤ 1% of all requests over a 7-day period.

## Measurement and Monitoring
These metrics are actively measured and collected using **Prometheus** from the `/metrics` endpoints exposed by the FastAPI microservices. The metrics are visualized in **Grafana** to track SLI performance against our defined SLOs.
