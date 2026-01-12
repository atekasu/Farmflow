# backend/seed.py
from __future__ import annotations

import models
from sqlalchemy.orm import Session

TRACTOR_ID = "TRACTOR-001"


def ensure_seed_data(db: Session) -> None:
    """
    既存DBでも安全に追加入力できる seed。
    - Machine が無ければ作成
    - MaintenanceItem は「id をキー」に不足分だけ追加（重複投入しない）
    """
    machine = db.query(models.Machine).filter(models.Machine.id == TRACTOR_ID).first()
    if machine is None:
        machine = models.Machine(
            id=TRACTOR_ID,
            name="No.1",
            model_name="SL54",
            total_hours=500,
        )
        db.add(machine)
        db.flush()

    existing_ids = {
        row[0]
        for row in (
            db.query(models.MaintenanceItem.id)
            .filter(models.MaintenanceItem.machine_id == TRACTOR_ID)
            .all()
        )
    }

    # type: engineOil, coolant, grease, airFilter, hydraulicOil, fuelFilter, transmissionOil, tirePressure, brakeWire
    # mode: intervalBased, inspectionOnly
    desired_items = [
        dict(
            id=f"{TRACTOR_ID}-engine-oil",
            machine_id=TRACTOR_ID,
            type="engineOil",
            name="エンジンオイル",
            mode="intervalBased",
            recommended_interval_hours=200,
            last_maintenance_at_hour=420,
        ),
        dict(
            id=f"{TRACTOR_ID}-hydraulic-oil",
            machine_id=TRACTOR_ID,
            type="hydraulicOil",
            name="作動油",
            mode="intervalBased",
            recommended_interval_hours=400,
            last_maintenance_at_hour=300,
        ),
        dict(
            id=f"{TRACTOR_ID}-transmission-oil",
            machine_id=TRACTOR_ID,
            type="transmissionOil",
            name="ミッションオイル",
            mode="intervalBased",
            recommended_interval_hours=300,
            last_maintenance_at_hour=250,
        ),
        dict(
            id=f"{TRACTOR_ID}-air-filter",
            machine_id=TRACTOR_ID,
            type="airFilter",
            name="エアフィルタ",
            mode="inspectionOnly",
        ),
        dict(
            id=f"{TRACTOR_ID}-fuel-filter",
            machine_id=TRACTOR_ID,
            type="fuelFilter",
            name="燃料フィルタ",
            mode="intervalBased",
            recommended_interval_hours=400,
            last_maintenance_at_hour=260,
        ),
        dict(
            id=f"{TRACTOR_ID}-coolant",
            machine_id=TRACTOR_ID,
            type="coolant",
            name="冷却水",
            mode="inspectionOnly",
        ),
        dict(
            id=f"{TRACTOR_ID}-grease",
            machine_id=TRACTOR_ID,
            type="grease",
            name="グリスアップ",
            mode="intervalBased",
            recommended_interval_hours=50,
            last_maintenance_at_hour=480,
        ),
        dict(
            id=f"{TRACTOR_ID}-tire-pressure",
            machine_id=TRACTOR_ID,
            type="tirePressure",
            name="タイヤ空気圧",
            mode="inspectionOnly",
        ),
        dict(
            id=f"{TRACTOR_ID}-brake-wire",
            machine_id=TRACTOR_ID,
            type="brakeWire",
            name="ブレーキワイヤ",
            mode="inspectionOnly",
        ),
    ]

    inserted = 0
    for data in desired_items:
        if data["id"] in existing_ids:
            continue
        db.add(models.MaintenanceItem(**data))
        inserted += 1

    if inserted > 0:
        db.commit()

    print(f"✓ seed: maintenance_items inserted={inserted}")
