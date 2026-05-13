from fastapi import FastAPI
from pydantic import BaseModel
import os
import json

app = FastAPI()


class CustomerOnboarding(BaseModel):
    company_name: str
    manager_name: str
    manager_email: str
    service_domain: str

    server_host: str
    ssh_port: int
    ssh_user: str
    web_service_port: int

    db_type: str
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str

    cpu_threshold: int
    memory_threshold: int
    min_instances: int
    max_instances: int


@app.get("/")
def root():
    return {"message": "FastAPI server is running"}


@app.post("/onboarding")
def save_onboarding(data: CustomerOnboarding):
    os.makedirs("configs", exist_ok=True)

    filename = f"configs/{data.company_name}.json"

    with open(filename, "w", encoding="utf-8") as f:
        json.dump(data.dict(), f, ensure_ascii=False, indent=4)

    return {
        "message": "Customer onboarding data saved",
        "file": filename
    }