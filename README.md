# Data Model (FarmFlow)

## Machine
- id: String (UUID)
- modelName: String
- maintenanceItems: List<MaintenanceItem>

## MaintenanceItem
- id: String (UUID)
- name: String
- recommendedHours: int （推奨交換時間）
- lastReplacedHours: int （前回交換時走行時間）
- currentHours: int （現在の走行時間）
- status: enum(good|warning|critical)

## Status 判定ルール（概要）
- usedHours = currentHours - lastReplacedHours
- ratio = usedHours / recommendedHours
- ratio < 0.7 → good
- 0.7 ≤ ratio < 1.0 → warning
- ratio ≥ 1.0 → critical

## その他
- Firebase Firestore に保存予定
- ドキュメント構造は `machines/{machineId}/maintenanceItems/{itemId}`