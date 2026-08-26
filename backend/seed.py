from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any

import database
import models
from sqlalchemy.orm import Session


STANDARD_INTERVALS = {
    "engineOil": 200,
    "hydraulicOil": 400,
    "fuelFilter": 400,
    "transmissionOil": 600,
}

EXTENDED_INTERVALS = {
    "engineOil": 240,
    "hydraulicOil": 450,
    "fuelFilter": 480,
    "transmissionOil": 650,
}

HEAVY_DUTY_INTERVALS = {
    "engineOil": 180,
    "hydraulicOil": 360,
    "fuelFilter": 360,
    "transmissionOil": 550,
}


# lib/data/tractor_dummy.dart の6台分と同じ初期値。
TRACTOR_SEEDS: tuple[dict[str, Any], ...] = (
    {
        "id": "TRACTOR-001",
        "name": "No.1",
        "model_name": "SL54",
        "total_hours": 500,
        "recommended_intervals": EXTENDED_INTERVALS,
        "last_maintenance_hours": {
            "engineOil": 420,
            "hydraulicOil": 380,
            "fuelFilter": 380,
            "transmissionOil": 300,
        },
        "inspection_days_ago": {
            "coolant": 18,
            "grease": 6,
            "airFilter": 21,
            "tirePressure": 8,
        },
    },
    {
        "id": "TRACTOR-002",
        "name": "No.2",
        "model_name": "MR70",
        "total_hours": 1200,
        "recommended_intervals": STANDARD_INTERVALS,
        "last_maintenance_hours": {
            "engineOil": 1050,
            "hydraulicOil": 1080,
            "fuelFilter": 1080,
            "transmissionOil": 1000,
        },
        "inspection_days_ago": {
            "coolant": 33,
            "grease": 12,
            "airFilter": 29,
            "tirePressure": 18,
        },
    },
    {
        "id": "TRACTOR-003",
        "name": "No.3",
        "model_name": "KL50",
        "total_hours": 1880,
        "recommended_intervals": HEAVY_DUTY_INTERVALS,
        "last_maintenance_hours": {
            "engineOil": 1700,
            "hydraulicOil": 1760,
            "fuelFilter": 1760,
            "transmissionOil": 1680,
        },
        "inspection_days_ago": {
            "coolant": 62,
            "grease": 17,
            "airFilter": 35,
            "tirePressure": 27,
        },
    },
    {
        "id": "TRACTOR-004",
        "name": "No.4",
        "model_name": "SL500",
        "total_hours": 800,
        "recommended_intervals": EXTENDED_INTERVALS,
        "last_maintenance_hours": {
            "engineOil": 750,
            "hydraulicOil": 680,
            "fuelFilter": 680,
            "transmissionOil": 600,
        },
        "inspection_days_ago": {
            "coolant": 14,
            "grease": 4,
            "airFilter": 19,
            "tirePressure": 7,
        },
        "precheck_statuses": {"engineOil": "warning"},
    },
    {
        "id": "TRACTOR-005",
        "name": "No.5",
        "model_name": "SL500",
        "total_hours": 2100,
        "recommended_intervals": STANDARD_INTERVALS,
        "last_maintenance_hours": {
            "engineOil": 1955,
            "hydraulicOil": 1770,
            "fuelFilter": 1980,
            "transmissionOil": 1900,
        },
        "inspection_days_ago": {
            "coolant": 44,
            "grease": 24,
            "airFilter": 38,
            "tirePressure": 32,
        },
        "precheck_statuses": {"engineOil": "critical"},
    },
    {
        "id": "TRACTOR-006",
        "name": "No.6",
        "model_name": "SL550",
        "total_hours": 50,
        "recommended_intervals": EXTENDED_INTERVALS,
        "last_maintenance_hours": {},
        "inspection_days_ago": {
            "coolant": 3,
            "grease": 2,
            "airFilter": 4,
            "tirePressure": 1,
        },
    },
)


def _maintenance_items(seed: dict[str, Any], now: datetime) -> list[dict[str, Any]]:
    tractor_id = seed["id"]
    total_hours = seed["total_hours"]
    intervals = seed["recommended_intervals"]
    maintenance_hours = seed.get("last_maintenance_hours", {})
    inspection_days = seed["inspection_days_ago"]
    precheck_statuses = seed.get("precheck_statuses", {})

    def interval_item(
        suffix: str,
        component_type: str,
        name: str,
        fallback_last_hour: int,
    ) -> dict[str, Any]:
        return {
            "id": f"{tractor_id}-{suffix}",
            "machine_id": tractor_id,
            "type": component_type,
            "name": name,
            "mode": "intervalBased",
            "recommended_interval_hours": intervals[component_type],
            "last_maintenance_at_hour": maintenance_hours.get(
                component_type, max(fallback_last_hour, 0)
            ),
            "last_inspection_date": None,
            "latest_precheck_status": precheck_statuses.get(component_type),
        }

    def inspection_item(
        suffix: str, component_type: str, name: str
    ) -> dict[str, Any]:
        return {
            "id": f"{tractor_id}-{suffix}",
            "machine_id": tractor_id,
            "type": component_type,
            "name": name,
            "mode": "inspectionOnly",
            "recommended_interval_hours": None,
            "last_maintenance_at_hour": None,
            "last_inspection_date": now
            - timedelta(days=inspection_days[component_type]),
            "latest_precheck_status": precheck_statuses.get(component_type),
        }

    # MachineFactory.createTractor と同じ順序・ID・デフォルト値にする。
    return [
        interval_item("engine-oil", "engineOil", "エンジンオイル", 0),
        inspection_item("coolant", "coolant", "クーラント"),
        inspection_item("grease", "grease", "グリス"),
        inspection_item("air-filter", "airFilter", "エアフィルタ"),
        interval_item(
            "hydraulic", "hydraulicOil", "油圧オイル", total_hours - 120
        ),
        interval_item(
            "fuel-filter", "fuelFilter", "燃料フィルタ", total_hours - 120
        ),
        interval_item(
            "transmission-oil",
            "transmissionOil",
            "トランスミッションオイル",
            total_hours - 200,
        ),
        inspection_item("tire-pressure", "tirePressure", "タイヤ空気圧"),
    ]


def _set_if_changed(instance: Any, field: str, value: Any) -> bool:
    if getattr(instance, field) == value:
        return False
    setattr(instance, field, value)
    return True


def ensure_seed_data(db: Session) -> None:
    """Flutterのデモ機体を、既存の運用履歴を保ったまま冪等投入する。"""
    now = datetime.now()
    inserted_machines = 0
    inserted_items = 0
    updated_rows = 0
    removed_legacy_items = 0

    for seed in TRACTOR_SEEDS:
        tractor_id = seed["id"]
        machine = db.get(models.Machine, tractor_id)
        if machine is None:
            machine = models.Machine(
                id=tractor_id,
                name=seed["name"],
                model_name=seed["model_name"],
                total_hours=seed["total_hours"],
            )
            db.add(machine)
            db.flush()
            inserted_machines += 1
        else:
            changed = False
            changed |= _set_if_changed(machine, "name", seed["name"])
            changed |= _set_if_changed(machine, "model_name", seed["model_name"])
            updated_rows += int(changed)

        desired_items = _maintenance_items(seed, now)
        desired_by_id = {item["id"]: item for item in desired_items}
        existing_items = {
            item.id: item
            for item in db.query(models.MaintenanceItem)
            .filter(models.MaintenanceItem.machine_id == tractor_id)
            .all()
        }

        # 初期のFastAPI seedで使っていたIDをFlutter側のIDへ移行。
        legacy_hydraulic_id = f"{tractor_id}-hydraulic-oil"
        hydraulic_id = f"{tractor_id}-hydraulic"
        legacy_hydraulic = existing_items.get(legacy_hydraulic_id)
        if legacy_hydraulic is not None and hydraulic_id not in existing_items:
            legacy_hydraulic.id = hydraulic_id
            existing_items.pop(legacy_hydraulic_id)
            existing_items[hydraulic_id] = legacy_hydraulic
            updated_rows += 1

        # brakeWire はFlutterのMachineFactoryから削除済み。過去seed由来の行だけ除去する。
        legacy_brake_id = f"{tractor_id}-brake-wire"
        legacy_brake = existing_items.pop(legacy_brake_id, None)
        if legacy_brake is not None:
            db.delete(legacy_brake)
            removed_legacy_items += 1

        for item_id, item_data in desired_by_id.items():
            existing = existing_items.get(item_id)
            if existing is None:
                db.add(models.MaintenanceItem(**item_data))
                inserted_items += 1
                continue

            changed = False
            # 名称・種別・推奨間隔はFlutterモデルを正として同期する。
            for field in (
                "machine_id",
                "type",
                "name",
                "mode",
                "recommended_interval_hours",
            ):
                changed |= _set_if_changed(existing, field, item_data[field])

            # 点検日と交換アワーは履歴なので、未設定時だけ初期値を入れる。
            if (
                existing.last_inspection_date is None
                and item_data["last_inspection_date"] is not None
            ):
                existing.last_inspection_date = item_data["last_inspection_date"]
                changed = True
            if (
                existing.last_maintenance_at_hour is None
                and item_data["last_maintenance_at_hour"] is not None
            ):
                existing.last_maintenance_at_hour = item_data[
                    "last_maintenance_at_hour"
                ]
                changed = True

            updated_rows += int(changed)

    db.commit()
    print(
        "✓ seed: "
        f"machines inserted={inserted_machines}, "
        f"maintenance_items inserted={inserted_items}, "
        f"rows updated={updated_rows}, "
        f"legacy items removed={removed_legacy_items}"
    )


if __name__ == "__main__":
    models.Base.metadata.create_all(bind=database.engine)
    session = database.SessionLocal()
    try:
        ensure_seed_data(session)
    finally:
        session.close()
