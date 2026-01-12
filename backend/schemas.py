# backend/schemas.py
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel


class MaintenanceItemSchema(BaseModel):
    id: str
    machine_id: str
    type: str
    name: str
    mode: str
    recommended_interval_hours: Optional[int] = None
    last_maintenance_at_hour: Optional[int] = None
    last_inspection_date: Optional[datetime] = None
    latest_precheck_status: Optional[str] = None

    class Config:
        from_attributes = True  # pydantic v2


class MachineSchema(BaseModel):
    id: str
    name: str
    model_name: str
    total_hours: int
    maintenance_items: List[MaintenanceItemSchema] = []

    class Config:
        from_attributes = True  # pydantic v2

class MaintenanceRecordIn(BaseModel):
    item_id:str
    current_hour:int
