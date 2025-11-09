from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import models
import database
from datetime import datetime

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="FarmFlow API")

@app.get("/")
def root():
    return {"message": "FarmFlow API is running"}

@app.get("/machines")
def get_machines(db: Session = Depends(database.get_db)):
    machines = db.query(models.Machine).all()
    return machines

@app.get("/machines/{machine_id}")
def get_machine(machine_id: str, db: Session = Depends(database.get_db)):
    machine = db.query(models.Machine).filter(models.Machine.id == machine_id).first()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")
    return machine

@app.post("/precheck")
def save_precheck(
    machine_id: str,
    result: dict,
    total_hours: int,
    db: Session = Depends(database.get_db)
):
    import uuid
    record = models.PreCheckRecord(
        id=str(uuid.uuid4()),
        machine_id=machine_id,
        check_date=datetime.now(),
        result=result,
        total_hours_at_check=total_hours
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return {"message": "PreCheck saved", "id": record.id}

@app.on_event("startup")
def insert_dummy_data():
    db = database.SessionLocal()
    
    if db.query(models.Machine).count() > 0:
        db.close()
        return
    
    machine = models.Machine(
        id="TRACTOR-001",
        name="No.1",
        model_name="SL54",
        total_hours=500
    )
    db.add(machine)
    
    item = models.MaintenanceItem(
        id="TRACTOR-001-engine-oil",
        machine_id="TRACTOR-001",
        type="engineOil",
        name="エンジンオイル",
        mode="intervalBased",
        recommended_interval_hours=200,
        last_maintenance_at_hour=420
    )
    db.add(item)
    
    db.commit()
    db.close()
    print("✓ ダミーデータを挿入しました")