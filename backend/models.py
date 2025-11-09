from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class Machine(Base):
    __tablename__ = "machines"
    
    id = Column(String, primary_key=True, index=True)
    name = Column(String)
    model_name = Column(String)
    total_hours = Column(Integer)
    
    maintenance_items = relationship("MaintenanceItem", back_populates="machine")

class MaintenanceItem(Base):
    __tablename__ = "maintenance_items"
    
    id = Column(String, primary_key=True, index=True)
    machine_id = Column(String, ForeignKey("machines.id"))
    type = Column(String)
    name = Column(String)
    mode = Column(String)
    recommended_interval_hours = Column(Integer, nullable=True)
    last_maintenance_at_hour = Column(Integer, nullable=True)
    last_inspection_date = Column(DateTime, nullable=True)
    latest_precheck_status = Column(String, nullable=True)
    
    machine = relationship("Machine", back_populates="maintenance_items")

class PreCheckRecord(Base):
    __tablename__ = "precheck_records"
    
    id = Column(String, primary_key=True, index=True)
    machine_id = Column(String)
    check_date = Column(DateTime, default=datetime.utcnow)
    result = Column(JSON)
    total_hours_at_check = Column(Integer, nullable=True)