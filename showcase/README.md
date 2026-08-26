# FarmFlow Showcase

FarmFlow のチーム共有用、閲覧専用の静的ポートフォリオページです。Flutter / FastAPI のアプリ本体とは分離しており、`showcase/` フォルダ単体で表示できます。

## ローカル表示

```bash
python3 -m http.server 4173 --directory showcase
```

`http://localhost:4173` を開いてください。HTML / CSS / JavaScript と画像のみで、ビルドやパッケージ導入は不要です。

## リポジトリを公開しない共有方法

- `showcase/` だけを ZIP にし、チームに共有する
- 静的ホスティングに `showcase/` の中身だけをドラッグ＆ドロップする
- 非公開リポジリのデプロイ設定で、ルートディレクトリを `showcase` に指定する

`noindex` メタタグと `robots.txt` は検索エンジン向けの拒否指示であり、アクセス制御ではありません。限定公開が必要な場合は、利用するホスティング側でパスワード保護またはチームアクセスを有効にしてください。

## 構成

```text
showcase/
├── index.html
├── styles.css
├── script.js
├── robots.txt
└── assets/
    ├── favicon.svg
    └── screenshots/
```
