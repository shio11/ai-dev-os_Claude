# JavaScript 追加ルール（Python アプリのブラウザ画面）

Python の `main.py` が起動するアプリの画面として、ブラウザで動く JavaScript のルール。この種類の JS には frameworks/nodejs-cli・nextjs の構成を当てはめず、こちらの構成に従う。common（security・validation 等）はそのまま適用する。

## 適用範囲
- 新規のファイル・関数には全て適用する。既存のファイルを直すときは、変更箇所だけに適用し、周辺の書き方（読み込み方式・命名・グローバル関数の使い方）に合わせる。
- ルールに合わせることだけを目的に、既存コードを書き換えない（例: 番号付きの classic script を ESM に移す）。必要なら提案し、承認後に行う。
- ブラウザ・Node.js 以外の組み込み JS エンジン（medini analyze 等）で動くスクリプトは対象外。

## 前提環境
- 実行環境は Windows の Edge / Chrome 最新版（ES2023 相当の構文・API を使ってよい）。
- Node.js・npm はない前提。ビルドツールやバンドラーを前提にしない。
- JS・HTML・CSS は UTF-8（BOM なし）。外部ライブラリは `static/lib/` にローカル保存してバージョンを明記し、CDN からは読み込まない。新しく入れるときは目的・ライセンス・サイズを示して提案する。

## 読み込み方式の判定（最初に決める）
- **Python のサーバーが配信する（`http://127.0.0.1:...` 等）** → ESM。`<script type="module" src="js/app.js">` で読み込み、名前付き `export` だけを使う（`export default` は使わない）。
- **Python が生成した単一 HTML をファイル（`file://`）で開く** → classic script（ESM は読み込めない）。各ファイルを IIFE で囲み、公開するものは名前空間1つ（例: `window.App`）に載せる。型は `globals.d.ts` で宣言する。Python のビルド処理で `lib → api → views → app` の順に結合して埋め込む。
- 既存プロジェクトに方式があれば、それに合わせる。
- 実装を提示するときは、選んだ方式と理由を最初に書く。

## Python との役割分担
- 業務ロジック（計算・判定・検証）の正は Python 側。JS は表示・画面操作・入力時の簡易チェック・Python API の呼び出しに限る。同じロジックを両方に書かない（やむを得ない場合は結果の一致を確かめるテストを付ける）。
- 例外: `file://` で開き、実行中に Python のサーバーがない方式では、業務ロジックを JS に置いてよい。Python 側にも同じロジックがあるなら照合テストを必須とする。
- Python から JS へのデータは、`fetch` で JSON を取得するか、`<script type="application/json" id="...">` に埋め込んで `JSON.parse(el.textContent)` で読む。埋め込む前に Python 側で `json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")` とする。JS のコード文字列に値を直接埋め込まない。
- 日付は ISO 8601 の文字列で受け渡す。日付のみ（`YYYY-MM-DD`）は `Date` に変換しない（UTC 扱いで日付がずれる）。
- Python で JS・HTML を読み書きするときは `encoding="utf-8"` を指定する。

## 構成
```
static/
├── index.html
├── style.css
└── js/
    ├── app.js     # 入口: 初期化・イベント登録・初期化失敗時のエラー表示のみ
    ├── api.js     # Python API の呼び出し（唯一の通信窓口）
    ├── types.js   # API の入出力の @typedef・ファクトリ関数・定数
    ├── lib.js     # 純粋関数（整形・入力チェック）
    └── views.js   # DOM の生成・更新
```
- 大きくなったら `api/`・`types/`・`lib/`・`views/<screen>.js` のフォルダに分ける（1ファイル200〜300行が目安）。
- 依存は `app → views → (api, lib) → types` の一方向。`fetch` は `api` だけ、`document` は `views` と `app` だけが触る。`app.js` 以外は読み込まれただけで副作用を起こさない。
- 構成案（ツリー）を最初に提示してから実装する。

## 型・不変性
- JS を置くフォルダに `jsconfig.json`（`checkJs: true`、`strict: true`、`noEmit: true`、`lib/`・`*.min.js` は除外）を置き、JSDoc で引数・戻り値・データ構造を型付けする。`any` は使わず、不明な値は `unknown` で受けて絞り込む。
- `types.js` の型は Python 側のモデルと項目名・型を1対1で対応させ、Python 側を変えたら同じ変更で更新する。
- データはクラスにせず、検証付きのファクトリ関数＋`Object.freeze` で表す。クラスは状態と振る舞いを持つものに限り、`#name` でカプセル化する。

## 通信・DOM
- `api.js` は `response.ok` を確認し、失敗時は API のエラーメッセージ（`detail` 等）を含む `Error` に変換して投げる。`AbortSignal.timeout()` でタイムアウトを付ける。
- 利用者に見せるエラーは画面に表示する（`alert`・`console` だけで済ませない）。
- DOM への文字列挿入は `textContent`・`createElement` を使い、API のデータや入力値を `innerHTML` に渡さない。

## テスト
- 画面の動作確認は、pytest から起動するブラウザテスト（E2E）を基本とする。`lib` の純粋関数は DOM・通信に依存させない。
