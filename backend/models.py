
# backend/models.py
from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Machine(Base):
    __tablename__ = "machines"

    id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String)
    model_name: Mapped[str] = mapped_column(String)
    total_hours: Mapped[int] = mapped_column(Integer)

    maintenance_items: Mapped[List["MaintenanceItem"]] = relationship(
        "MaintenanceItem",
        back_populates="machine",
        cascade="all, delete-orphan",
    )


class MaintenanceItem(Base):
    __tablename__ = "maintenance_items"

    id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    machine_id: Mapped[str] = mapped_column(ForeignKey("machines.id"), index=True)

    type: Mapped[str] = mapped_column(String)
    name: Mapped[str] = mapped_column(String)
    mode: Mapped[str] = mapped_column(String)

    recommended_interval_hours: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    last_maintenance_at_hour: Mapped[int] = mapped_column(Integer, nullable=True)

    last_inspection_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    latest_precheck_status: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    machine: Mapped["Machine"] = relationship("Machine", back_populates="maintenance_items")


class PreCheckRecord(Base):
    __tablename__ = "precheck_records"

    id: Mapped[str] = mapped_column(String, primary_key=True, index=True)
    machine_id: Mapped[str] = mapped_column(String)
    check_date: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    result: Mapped[dict] = mapped_column(JSON)
    total_hours_at_check: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)