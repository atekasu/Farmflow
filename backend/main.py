# backend/main.py
import uuid
from datetime import datetime
from typing import List

import time
import database
import models
import schemas
import seed
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session, selectinload

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="FarmFlow API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    db = database.SessionLocal()
    try:
        seed.ensure_seed_data(db)
    finally:
        db.close()


@app.get("/")
def root():
    return {"message": "FarmFlow API is running"}


@app.get("/machines", response_model=List[schemas.MachineSchema])
def get_machines(db: Session = Depends(database.get_db)):
    machines = (
        db.query(models.Machine)
        .options(selectinload(models.Machine.maintenance_items))
        .all()
    )
    return machines


@app.get("/machines/{machine_id}", response_model=schemas.MachineSchema)
def get_machine(machine_id: str, db: Session = Depends(database.get_db)):
    machine = (
        db.query(models.Machine)
        .options(selectinload(models.Machine.maintenance_items))
        .filter(models.Machine.id == machine_id)
        .one_or_none()
    )
    if machine is None:
        raise HTTPException(status_code=404, detail="Machine not found")
    return machine


@app.post("/precheck")
def save_precheck(
    machine_id: str,
    result: dict,
    total_hours: int,
    db: Session = Depends(database.get_db),
):
    record = models.PreCheckRecord(
        id=str(uuid.uuid4()),
        machine_id=machine_id,
        check_date=datetime.now(),
        result=result,
        total_hours_at_check=total_hours,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return {"message": "PreCheck saved", "id": record.id}


@app.post("/machines/{machine_id}/maintenance")
def record_maintenance(
    machine_id: str,
    body: schemas.MaintenanceRecordIn,
    db: Session = Depends(database.get_db),
):
    
    item = (
        db.query(models.MaintenanceItem)
        .filter(models.MaintenanceItem.id == body.item_id)
        .one_or_none()
    )
    if item is None:
        raise HTTPException(
            status_code=404,
            detail=f"MaintenanceItem not found: {body.item_id}",
        )

    if item.machine_id != machine_id:
        raise HTTPException(status_code=400, detail="machine_id mismatch for item_id")

    item.last_maintenance_at_hour = body.current_hour
    item.latest_precheck_status = None

    db.add(item)
    db.commit()
    db.refresh(item)

    return {
        "item_id": item.id,
        "machine_id": item.machine_id,
        "last_maintenance_at_hour": item.last_maintenance_at_hour,
        "latest_precheck_status": item.latest_precheck_status,
    }
