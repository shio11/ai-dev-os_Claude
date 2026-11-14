---
name: javascript
description: Python（main.py）が起動するアプリの画面としてブラウザで動く JavaScript を実装・生成する際のルール。Python との役割分担、読み込み方式（サーバー配信なら ESM／単一 HTML なら IIFE）、app/api/types/lib/views の構成、JSDoc＋jsconfig による型付け、不変性、エラー処理、DOM の安全性を定める。JavaScript の新規作成・実装時、および既存の JavaScript・HTML 内のスクリプトを修正する時に使用する。
---
# JavaScriptコード生成ルール

JavaScript を実装・生成する際は、以下のルールに従うこと。

## 適用範囲
- 新規ファイル・新規関数には本ルールを全て適用する
- 既存ファイルを修正する場合は、変更箇所にのみ適用し、周辺コードの書き方（読み込み方式・命名・グローバル関数の使い方等）に合わせる
- ルールに合わせることだけを目的に既存コードを書き換えない（例: 番号付きの classic script を ESM に移行する）。必要と判断した場合は提案し、承認後に行う
- ブラウザ・Node.js 以外の組み込み JS エンジン（medini analyze 等）で動くスクリプトは対象外とする

## 前提環境
- アプリの起動元は Python の `main.py` であり、JavaScript はその画面（ブラウザ）として動く
- 実行環境は Windows 上の Microsoft Edge / Google Chrome の最新版とする（ES2023 相当の構文・API を使ってよい）
- Node.js・npm はない前提とする。npm を使えるプロジェクトでのみ、任意項目（ESLint 等）を適用する

## 文字コード・外部ライブラリ
- JS・HTML・CSS は UTF-8（BOM なし）で保存し、HTML には `<meta charset="utf-8">` を入れる
- Python で JS・HTML を読み書き・生成する場合は、必ず `encoding="utf-8"` を指定する（Windows の既定は cp932 のため、指定しないと日本語が文字化けする）
- 外部ライブラリは `static/lib/` にローカル保存し、バージョンをファイル名（例: `exceljs-4.4.0.min.js`）または先頭コメントで明記する
- CDN からは読み込まない（オフライン・社内ネットワークで動かなくなるため）
- 外部ライブラリを新しく導入する場合は、目的・ライセンス・サイズを示して提案し、承認後に導入する

## Python との役割分担
- 業務ロジック（計算・判定・検証・データの整合性）の正は Python 側に置く
- JavaScript の責務は、表示・画面操作・入力時の簡易チェック・Python API の呼び出しに限る
- 同じロジックを Python と JavaScript の両方に実装しない。表示の都合などでどうしても必要な場合は、両者の結果が一致することを確認するテストを必ず付ける
- 例外: Python が生成した単一 HTML をファイル（`file://`）として開き、実行中に Python のサーバーが存在しない方式では、業務ロジックを JavaScript に置いてよい
  - その場合も、同じロジックを Python 側（生成処理・集計等）にも持つなら、両者の結果が一致することを確認する照合テストを必須とする
- Python から JavaScript へのデータの受け渡しは、次のどちらかに限る
  - API（`fetch`）で JSON を取得する
  - HTML に `<script type="application/json" id="...">` として埋め込み、`JSON.parse(element.textContent)` で読む
    - 埋め込む前に Python 側で `json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")` として `<` をエスケープする（データ中の `</script>` で要素が閉じ、表示崩れやスクリプト注入が起きるのを防ぐ）
- Python 側で JavaScript のコード文字列に値を直接埋め込まない（`f"const data = {value};"` 等）。HTML/JS の破損やスクリプト注入の原因になる
- 日付・日時は Python との間で ISO 8601 の文字列として受け渡す
  - 日付のみの値（`YYYY-MM-DD`）は `Date` に変換せず文字列のまま扱う（`new Date("2026-10-31")` は UTC の0時と解釈され、日本時間の処理で日付がずれる原因になる）
  - 日時の表示は `Intl.DateTimeFormat("ja-JP", ...)` を使う

## 設計要件

### 責務とカプセル化
- 関数型を優先する。状態を持たない処理は純粋関数にし、副作用（DOM 操作・通信）は `views` と `api` に寄せる
- データ（API の入出力・値オブジェクト）はクラスにせず、「検証を行うファクトリ関数＋`Object.freeze` したプレーンオブジェクト」で表す
- クラスは、状態と振る舞いを併せ持つもの（画面の状態管理・複雑なウィジェット等）に限る
  - インスタンス変数は `#name`（private フィールド）でカプセル化する。命名規約だけの `_name` は使わない
  - 公開が必要な値は `get` / `set` を介して扱い、setter・コンストラクタで値を検証する
- 継承よりコンポジションを優先し、継承は「is-a」関係が明確な場合のみ使う
- グローバルに置く名前は最小限にする（ESM なら0、classic script なら名前空間1つ）

```javascript
/** @typedef {Readonly<{ partNo: string, quantity: number }>} StockItem */

/**
 * @param {string} partNo
 * @param {number} quantity
 * @returns {StockItem}
 */
export function createStockItem(partNo, quantity) {
  if (partNo === "") {
    throw new RangeError("partNo が空です");
  }
  if (!Number.isInteger(quantity) || quantity < 0) {
    throw new RangeError(`quantity が不正です: ${quantity}`);
  }
  return Object.freeze({ partNo, quantity });
}
```

### 型付け
- プロジェクト（JS を置くフォルダ）直下に `jsconfig.json` を置き、`checkJs` と `strict` を有効にする。VS Code 上で型エラーが0の状態を保つこと

```json
{
  "compilerOptions": {
    "checkJs": true,
    "strict": true,
    "noEmit": true,
    "target": "ES2023",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2023", "DOM", "DOM.Iterable"]
  },
  "include": ["**/*.js", "**/*.d.ts"],
  "exclude": ["**/lib/**", "**/dist/**", "**/*.min.js"]
}
```
- 外部ライブラリ（`lib/`）・ビルド成果物（`dist/`）・圧縮済みファイルは型検査の対象から外す
- jsconfig を置けない単体ファイルのみ、先頭の `// @ts-check` で代用する
- 全ての関数の引数・戻り値・データ構造を JSDoc（`@param` / `@returns` / `@typedef` / `@type`）で型付けする
- `any` / `{*}` / `Object` は使わない。型が不明な値は `unknown` として受け、ガード関数で絞り込む
- API の入出力の型は `types.js` に `@typedef` でまとめ、Python 側のモデル（Pydantic・dataclass 等）と項目名・型を1対1で対応させる。Python 側を変更したら同じ変更で `types.js` も更新する
- API のレスポンス・埋め込み JSON・`localStorage`・フォーム値・URL パラメータは信頼せず、受け取った境界で検証してから内部に渡す

### 不変性
- `var` は使わない。原則 `const`、再代入が必要な場合のみ `let`
- 引数・共有データを直接変更しない。更新は新しい値を返す（スプレッド構文、`map` / `filter` / `reduce`、`toSorted` / `toSpliced` / `with`）
- `structuredClone` はプレーンデータにのみ使う。クラスのインスタンスはプロトタイプと private フィールドが失われるため、新しいインスタンスを返すメソッド（例: `withQuantity(quantity)`）で複製する
- 定数は `UPPER_SNAKE_CASE`、列挙値は `Object.freeze({...})` で定義する。マジックナンバー・マジック文字列は名前付き定数にする

### スタイル
- 等価比較は `===` / `!==` のみ
- 既定値・存在確認は `??` / `?.` を使い、`||` による falsy 判定の誤りを避ける
- 早期リターンでネストを浅くする。1関数1目的とし、引数が3つ以上ならオブジェクト引数にする
- 命名: 変数・関数は `camelCase`、クラス・typedef は `PascalCase`、真偽値は `is` / `has` / `can` 始まり、関数は動詞始まり
- コメントは「なぜ」を書く。「何をしているか」はコードで表現する

### エラー処理
- 空の `catch` は禁止。処理できないエラーは再スローし、処理する場合は意味のあるメッセージを付ける
- `throw` するのは `Error`（またはそのサブクラス）のみ。文字列やプレーンオブジェクトを投げない
- 原因を保持するため `new Error("説明", { cause: err })` を使う
- `catch (err)` の `err` は `unknown` として扱い、`instanceof` で絞り込んでから使う
- 利用者に見せるエラーは画面上に表示する（`alert` や `console` だけで済ませない）。Python API が返すエラーメッセージ（`detail` 等）は、そのまま利用者向けの表示に使えるようにする

### API 通信
- Python API の呼び出しは `api.js` に集約し、`views` から `fetch` を直接呼ばない
- `api.js` は `response.ok` を必ず確認し、失敗時は API のエラーメッセージを含む `Error` に変換して投げる
- 通信は `async` / `await` で書き、Promise を放置しない（`await` するか、`.catch` でエラーを表示する）
- 独立した取得処理は `Promise.all` で並列化する
- 通信には `AbortSignal.timeout()` でタイムアウトを付ける。呼び出し元の `signal` がある場合は `AbortSignal.any()` で両方を有効にする（上書きしない）
- 応答の JSON が解析できない場合、成功レスポンスなら throw する。失敗レスポンスに限り、`statusText` で代替してよい

```javascript
const TIMEOUT_MS = 30_000;
const NO_CONTENT = 204;

/**
 * @param {string} path
 * @param {RequestInit} [init]
 * @returns {Promise<unknown>}
 */
async function request(path, init = {}) {
  const signals = [AbortSignal.timeout(TIMEOUT_MS), init.signal].filter((s) => s instanceof AbortSignal);
  const response = await fetch(path, { ...init, signal: AbortSignal.any(signals) });
  const method = init.method ?? "GET";
  if (!response.ok) {
    throw new Error(`${method} ${path} が失敗しました: ${await readErrorDetail(response)}`);
  }
  if (response.status === NO_CONTENT) {
    return null;
  }
  try {
    // response.json() は any を返すため、unknown として受けてから絞り込む
    return /** @type {unknown} */ (await response.json());
  } catch (err) {
    throw new Error(`${method} ${path} の応答を JSON として解析できませんでした`, { cause: err });
  }
}

/**
 * @param {Response} response
 * @returns {Promise<string>}
 */
async function readErrorDetail(response) {
  // エラー応答は JSON とは限らないため、解析できない場合は statusText で代替する
  const body = /** @type {unknown} */ (await response.json().catch(() => null));
  if (body !== null && typeof body === "object" && "detail" in body) {
    return String(body.detail);
  }
  return response.statusText;
}
```

### DOM
- DOM への文字列挿入は `textContent` / `createElement` を使う。`innerHTML` に API のデータ・入力値を渡さない（XSS 対策）
- `eval` / `new Function` / 文字列を渡す `setTimeout` は使わない
- `querySelector` の戻り値は `null` になりうるため必ず扱う。必須要素の取得は「見つからなければ要素名付きで throw するヘルパー」にまとめる
- イベントは委譲（親要素で受けて `event.target` で振り分け）を優先する
- 再描画で作り直す要素のリスナーは、`AbortController` の `signal` でまとめて解除する

## プログラム構成

### 読み込み方式の判定
まず HTML がどう開かれるかを確認し、読み込み方式を決めること。

- **Python のサーバーが配信する（`http://127.0.0.1:...` 等で開く）** → ESM を使う
  - HTML から `<script type="module" src="js/app.js">` で読み込む
  - 名前付き `export` を使い、`export default` は使わない
  - モジュールは遅延実行されるため、`DOMContentLoaded` を待たずに `app.js` のトップレベルで初期化してよい
- **Python が1つの HTML を生成し、ファイルとして開く（`file://`）** → classic script を使う
  - `file://` ではブラウザの制限でモジュールを読み込めないため、ESM は使えない
  - 各ファイルを IIFE で囲み、公開するものだけを名前空間オブジェクト1つ（例: `window.App`）に載せる
  - `strict` の型検査で `window.App` がエラーにならないよう、`globals.d.ts` に名前空間の型を宣言する。`.d.ts` ファイルはこの用途に限り例外として許可する

  - classic script のファイルはモジュールではないため `typeof import(...)` は使えない。公開する関数の型を直接書く
  - `@typedef` は IIFE の外（ファイル先頭）に書き、他のファイルや `globals.d.ts` から参照できるようにする

```typescript
// globals.d.ts
interface Window {
  App: {
    api: {
      fetchStock: () => Promise<unknown>;
    };
    views: {
      renderStock: (items: readonly StockItem[]) => void;
    };
  };
}
```
  - Python のビルド処理で、決めた順序（`lib → api → views → app`）で結合して HTML に埋め込む
- 既存プロジェクトの方式（例: 番号付きファイルの classic script）がある場合は、それに合わせる

### 小規模プロジェクト向け構成
画面が1〜2個程度で、各ファイルが200〜300行に収まる場合。

```
static/
├── index.html
├── style.css
└── js/
    ├── app.js     # 入口: 初期化・イベント登録のみ
    ├── api.js     # Python API の呼び出し（唯一の通信窓口）
    ├── types.js   # API の入出力の @typedef・ファクトリ関数・定数
    ├── lib.js     # 純粋関数（表示用の整形・入力チェック）
    └── views.js   # DOM の生成・更新
```
- ファイルが肥大化した場合や、画面ごとに責務が分かれてきた場合は、中〜大規模向け構成に移行する

### 中〜大規模プロジェクト向け構成
画面が複数あり、画面ごとの処理が大きい場合。

```
static/
├── index.html
├── css/
└── js/
    ├── app.js            # 入口: 初期化・画面の切り替え
    ├── api/              # 通信（リソースごとにファイルを分けてよい）
    ├── types/            # API の入出力の型・ファクトリ関数
    ├── lib/              # 純粋関数
    └── views/
        └── <screen>.js   # 画面ごとの DOM 操作と、その画面のイベント処理
```
- ファイル分割は「責務のまとまり単位」で行う。1ファイルの目安は200〜300行を上限とする
- 依存方向は `app → views → (api, lib) → types` の一方向とする。`views` 同士で直接呼び合わない（共通処理は `lib` に移す）
- `fetch` を呼んでよいのは `api`、`document` を触ってよいのは `views` と `app` だけとする

### 共通ルール（規模によらず）
- `app.js` の役割は次に限る
  - 必要なモジュールの読み込み
  - 初期データの取得（`api` 経由）と初回描画（`views` 経由）
  - 画面全体のイベント登録
  - 初期化失敗時のエラー表示
- `app.js` に業務ロジックや DOM 構築の詳細を書かない
- `app.js` 以外のファイルは、読み込まれただけで副作用（DOM 操作・通信・グローバル変更）を起こさない
- ディレクトリ構成案を最初に提示してから実装する

## テスト
- 画面の動作確認は、既存プロジェクトと同様に pytest から起動するブラウザテスト（E2E）で行うことを基本とする
- `lib` の純粋関数は単体でテストできるように保つ（DOM・通信に依存させない）
- 既存のテストを確認なしに削除・コメントアウトしない

## 任意: npm を使えるプロジェクトの場合
- ESLint（flat config）で、最低限 `eqeqeq` / `no-var` / `prefer-const` / `no-empty` / `no-eval` / `no-implied-eval` / `no-new-func` / `no-throw-literal` / `require-await` を有効にする
- 設定ファイル（`eslint.config.js` 等）はツールの要求に従い `export default` を使ってよい

## 付録: Node.js でツールを作る場合
画面ではなく、Node.js で動く補助ツール（照合・ビルド等）を作る場合のみ適用する。
- `package.json` に `"type": "module"` と `"engines": { "node": ">=22" }` を設定する
- 組み込みモジュールは `node:` プレフィックス付きで読み込み、ファイル操作は `node:fs/promises` を使う
- 入口は `main()` 関数とし、`main().catch((err) => { console.error(err); process.exitCode = 1; })` で失敗時に非0で終了させる（`process.exit()` は出力が途切れるため使わない）
- 可能であれば、Node ツールではなく Python で実装することを先に検討する

## 出力形式
新規に JavaScript を実装する際は、以下の順で提示すること。
- 読み込み方式（ESM / classic script）とその判断理由
- ディレクトリ構成（ツリー形式）
- 各ファイルの実装コード（Python 側の API・型の変更が必要な場合はそれも含める）
- 設計の意図（Python との役割分担、ファイル分割の理由）を簡潔に説明
