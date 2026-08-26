# backend/schemas.py
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict


# 各スキーマの設定を「class Config:」から「model_config = ConfigDict(...)」へ変更。
# Pydantic V2 でクラス形式の Config は非推奨になり、V3.0 で削除される予定のため。
# from_attributes=True の意味は変わらず、SQLAlchemy のモデル(ORMオブジェクト)を
# 属性アクセス経由でそのままスキーマに変換できるようにする指定。
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

    model_config = ConfigDict(from_attributes=True)


class MachineSchema(BaseModel):
    id: str
    name: str
    model_name: str
    total_hours: int
    maintenance_items: List[MaintenanceItemSchema] = []

    model_config = ConfigDict(from_attributes=True)

class MaintenanceRecordIn(BaseModel):
    item_id:str
    current_hour:int
