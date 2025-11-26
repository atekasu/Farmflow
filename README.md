# FarmFlow

農業機械のメンテナンス管理システム

![Status](https://img.shields.io/badge/status-in%20development-yellow)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green)

## 📖 プロジェクト概要

FarmFlowは、農業現場での機械メンテナンス管理を効率化するモバイルアプリケーションです。
6年間の農業実務経験から得た課題を解決するために開発しています。

### 解決する課題
- 📋 紙ベースの点検記録による情報の散逸
- ⚠️ メンテナンス時期の見落としによる機械故障
- 🔧 複数機械の状態把握の困難さ

### 主な機能
- ✅ 機械一覧の表示と状態の可視化
- ✅ 稼働時間ベースのメンテナンス管理
- ✅ 使用前点検記録の保存
- ✅ メンテナンス状態のリアルタイム評価（good/warning/critical）

## 🛠️ 技術スタック

### Frontend（実装完了）
- **Flutter** 3.x
- **Riverpod** - 状態管理
- **Dart** - プログラミング言語

### Backend（実装中 - 2025年12月完成予定）
- **FastAPI** - RESTful API フレームワーク
- **SQLAlchemy** - ORM
- **SQLite** - データベース
- **Python** 3.11+

### 今後の予定
- 🚧 Flutter-Backend連携
- 🚧 データ永続化の実装
- 📱 iOSビルドとテスト

## 📱 スクリーンショット

<!-- TODO: スクリーンショットを追加 -->
*準備中*

## 🗂️ データモデル

### Machine（機械）
```dart
class Machine {
  final String id;              // 機械ID（例: "TRACTOR-001"）
  final String name;            // 機械名（例: "No.1"）
  final String modelName;       // 型式（例: "SL54"）
  final int totalHours;         // 累計稼働時間
  final List<MaintenanceItem> maintenanceItems;
  final PreCheckRecord? lastPreCheck;
}
```

### MaintenanceItem（メンテナンス項目）
```dart
class MaintenanceItem {
  final String id;
  final ComponentType type;     // engineOil, hydraulicOil, etc.
  final String name;            // 表示名
  final ComponentMode mode;     // intervalBased or inspectionOnly
  final int? recommendedIntervalHours;   // 推奨交換間隔
  final int? lastMaintenanceAtHour;      // 最終メンテ時の稼働時間
  final DateTime? lastInspectionDate;    // 最終点検日
  final CheckStatus? latestPreCheckStatus;  // 使用前点検の結果
}
```

### PreCheckRecord（点検記録）
```dart
class PreCheckRecord {
  final String id;
  final String machineId;
  final DateTime checkDate;
  final Map<String, CheckStatus> result;  // 点検結果（JSON形式）
  final int? totalHoursAtCheck;
}
```

## 📊 ステータス判定ロジック

### 時間ベース（intervalBased）
```
usedHours = currentHour - lastMaintenanceAtHour
remainingRatio = (recommendedInterval - usedHours) / recommendedInterval

remainingRatio >= 0.3  → good     (緑)
0.2 <= remainingRatio < 0.3 → warning  (黄)
remainingRatio < 0.2   → critical (赤)
```

### 点検ベース（inspectionOnly）
```
daysSinceLastInspection = today - lastInspectionDate

< 30日  → good
30-60日 → warning
> 60日  → critical
```

### 複合評価
時間ベースと点検結果の**より厳しい方**を採用
```dart
finalStatus = max(timeBasedStatus, preCheckStatus)
```

## 🏗️ アーキテクチャ

### Phase 1（現在）: スタンドアロン版
```
Flutter App
└── MachineRepositoryImpl (メモリ内管理)
    └── Dummy Data
```

### Phase 2（実装中）: Backend連携版
```
Flutter App
└── MachineRepositoryApi (HTTP通信)
    └── FastAPI Backend
        └── SQLite Database
```

### ディレクトリ構造（Frontend）
```
lib/
├── model/              # ドメインモデル
│   ├── machine.dart
│   ├── maintenance_item.dart
│   └── precheck_record.dart
├── data/               # データ層
│   ├── machine_repository.dart
│   └── tractor_dummy.dart
├── domain/             # ビジネスロジック
│   └── machine_factory.dart
└── presentation/       # UI層
    └── (各種画面)
```

### ディレクトリ構造（Backend）
```
backend/
├── main.py            # FastAPI アプリケーション
├── models.py          # SQLAlchemy モデル
├── database.py        # DB接続設定
└── farmflow.db        # SQLite データベース
```

## 🚀 セットアップ

### Frontend（Flutter）
```bash
# 依存関係のインストール
flutter pub get

# アプリの起動
flutter run
```

### Backend（FastAPI）※実装中
```bash
# 仮想環境の作成・アクティベート
cd backend
python -m venv venv
source venv/bin/activate  # Mac/Linux
# venv\Scripts\activate   # Windows

# 依存関係のインストール
pip install fastapi sqlalchemy uvicorn

# サーバー起動
uvicorn main:app --reload
```

APIドキュメント: http://localhost:8000/docs

## 📝 API仕様（実装中）

### GET /machines
全機械の一覧を取得

**Response:**
```json
[
  {
    "id": "TRACTOR-001",
    "name": "No.1",
    "model_name": "SL54",
    "total_hours": 500
  }
]
```

### GET /machines/{machine_id}
特定機械の詳細を取得

### POST /precheck
使用前点検記録を保存

**Request Body:**
```json
{
  "machine_id": "TRACTOR-001",
  "result": {
    "engine_oil": "good",
    "tire": "warning"
  },
  "total_hours": 505
}
```

## 🎯 開発の背景

### なぜこのアプリを作ったのか
農業法人で6年間勤務する中で、以下の課題に直面しました：

1. **紙の点検表の管理負担**
   - 紛失リスク
   - 過去データの検索困難
   - 複数人での情報共有の難しさ

2. **メンテナンス時期の管理**
   - 稼働時間の記録漏れ
   - 交換時期の見落とし
   - 緊急故障によるダウンタイム

3. **非効率な作業フロー**
   - 点検のたびに紙を探す
   - 手書きによる記入ミス
   - データの集計・分析不可

これらを解決し、**現場の作業効率を向上させる**ことを目指しています。

## 🎓 学習成果

このプロジェクトを通じて習得したスキル：

### Flutter
- ✅ Riverpodによる状態管理
- ✅ 複雑なドメインモデルの設計
- ✅ イミュータブルなデータ構造
- ✅ Extension methodsの活用

### Backend（学習中）
- 🚧 FastAPIによるRESTful API設計
- 🚧 SQLAlchemyによるORM操作
- 🚧 データベース設計と正規化
- 🚧 API認証・認可（今後実装予定）

### ソフトウェア設計
- ✅ Domain-Driven Design（DDD）の実践
- ✅ Repository パターン
- ✅ Factory パターン
- ✅ テスト駆動開発の思考法

## 📅 開発ロードマップ

### Phase 1: MVP（完了）
- ✅ Flutter UIの実装
- ✅ ドメインロジックの実装
- ✅ ダミーデータでの動作確認

### Phase 2: Backend連携（実装中 - 2025年12月）
- 🚧 FastAPI バックエンドの実装
- 🚧 SQLiteデータベースの構築
- 🚧 Flutter-Backend間のHTTP通信実装

### Phase 3: 本番対応（2026年1月以降予定）
- ⏳ ユーザー認証機能
- ⏳ クラウドデプロイ（Railway/Render）
- ⏳ マルチデバイス対応
- ⏳ データバックアップ機能

## 👤 開発者

**Atekasu** - 農業法人勤務（6年）→ IT業界への転職を目指して学習中

- 🌾 農業現場の課題を技術で解決したい
- 💻 独学でプログラミングを5年間継続
- 📚 Flutter, Python, FastAPIを習得中

## 📄 ライセンス

このプロジェクトは個人学習・ポートフォリオ目的で開発されています。
