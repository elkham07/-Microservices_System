import requests
import threading
import time
import random

# scripts/load_test.py
# System load simulation for Capacity Planning (Assignment 6 - 5.3)

SERVICES = {
    "auth": "http://localhost:80/auth/health", # Using frontend gateway
    "product": "http://localhost:80/product/health",
    "order": "http://localhost:80/order/health"
}

def make_requests(service_url, duration):
    end_time = time.time() + duration
    count = 0
    errors = 0
    while time.time() < end_time:
        try:
            resp = requests.get(service_url, timeout=1)
            if resp.status_code != 200:
                errors += 1
            count += 1
        except:
            errors += 1
        time.sleep(0.01) # Small delay to control RPS
    print(f"Finished stress test for {service_url}. Total requests: {count}, Errors: {errors}")

def run_stress_test(duration=30, threads_per_service=5):
    print(f"--- Starting Load Simulation for {duration} seconds ---")
    threads = []
    for name, url in SERVICES.items():
        for _ in range(threads_per_service):
            t = threading.Thread(target=make_requests, args=(url, duration))
            t.start()
            threads.append(t)
    
    for t in threads:
        t.join()
    print("--- Load Simulation COMPLETE ---")

if __name__ == "__main__":
    run_stress_test()
