# medini analyze スクリプトのルール

Ansys medini analyze 25.1 のスクリプト機能（Rhino エンジン）で動く JavaScript のルール。既存のスクリプト（shio11/medini の `scripts/`）の書き方を踏襲する。

## 適用範囲と common との関係
- medini のスクリプトには、common のうち次は**適用しない**（このファイルが優先）: ES2015 以降の構文、`export`/`import`、JSDoc の型と `checkJs`、`Object.freeze`、lint、node:test・E2E のテスト方法、ブラウザ・Node.js 向けの構成。
- common のうち次は**適用する**: 命名の考え方（naming.md）、コメントは「なぜ」を書く（comment-format.md。ただしコメントは日本語でよい）、利用者向けメッセージの書き方（error-handling.md の 5）、秘密情報や個人のパスを書かない（security.md）。

## 構文（Rhino・ES5 相当）
- `var` と `function` だけを使う。`let`・`const`・アロー関数・`class`・テンプレート文字列・分割代入・`for...of`・Promise・`async` は使わない（既存スクリプトで使っておらず、動作が確認できていないため）。
- 配列は `forEach`・`map`・`filter`・`indexOf` を使ってよい。
- Java の機能は `java.*` / `javax.*` / `Packages.*` で直接呼ぶ。Java の文字列は `String(...)` で JS の文字列に直してから比較・加工する。小数の属性には `new java.math.BigDecimal(値)` を渡す。

## ファイル構成
- 1 スクリプト = 1 ファイル（`scripts/<名前>.js`）で完結させる。ほかのファイルは読み込まない。共通の処理（CSV 読み込み、ファイル選択など）は各ファイルにコピーし、「(xxx.js と同じ)」と注記する。
- スクリプトを作ったら、解説書 `docs/<名前>.md` をセットで作り、`docs/README.md` の表に追加する。解説書は、コードを小さなステップに分け、すぐ下に何をしているかを、プログラミングに詳しくない人向けの日本語で書く。

## ファイルの先頭
1. 書き込み・作成をするスクリプトは、1 行目に `//$EXPERIMENTAL$  $ENHANCED_CONTAINMENT_ACCESS$` を入れる。
2. 続けてヘッダーのブロックコメントに次を書く。
   - 何をするスクリプトか
   - 入力 CSV の形式（列名と、書き込み先の属性名の対応）
   - 根拠（Metamodel Doc・Scripting Doc・User Guide の章番号）
   - 実機で確認済みの事項と未確認の事項（日付付き）
   - 使い方（Model Browser で何を選択して実行するか）
3. 設定値を `var` の大文字定数で並べ、各行にコメントで意味を書く。基本は `DRY_RUN`（true で書き込まずに確認だけ）、`USE_FILE_DIALOG`、`DEFAULT_PATH`（`C:\\work\\...` のような汎用のパス。個人のフォルダは書かない）。実機で調べた参照名・enum 値も、ここに定数で置く。

## 処理の組み立て
- 処理を関数に分け、最後に `main();` を呼ぶ。`main` は次の順にする。
  1. 選択のチェック（`selection` の数と型。違えば `throw "〇〇を1つ選択してください"`）
  2. ファイル選択（キャンセルなら `alert("キャンセルしました")` で終了）
  3. CSV の読み込み
  4. 事前チェック: 書き込む前に CSV 全体を検証し、問題を一覧で `alert` する。1 件でもあれば書き込まない
  5. `DRY_RUN` なら、照合結果を `console.log` に出して `alert` で件数を示し、書き込まずに終了
  6. 書き込み
  7. `alert` で件数と次にする操作を示す（詳細は `console.log`）
- CSV の読み込みは既存の `readCsv` の形にする: UTF-8 で読み、`U+FFFD` があれば MS932 で読み直す、BOM を除く、`"` で囲まれた値に対応する、ヘッダー 1 行を飛ばす。
- ファイル選択は既存の `chooseCsv` の形にする: SWT の FileDialog → Swing の JFileChooser → `prompt` の順に試し、画面スレッドの呼び出しは `runOnUiThread` でタイムアウト付きにする。

## モデルの操作
- 要素の検索は `selection`・`finder`・`Global.getFinder(x).findByType(Metamodel.xxx.Yyy, false).asList()` を使う。
- 要素の作成は EMF の EFactory を使う（`.lib/factory.js` は無い）。属性の読み書きは既存の `emf()`・`setAttr()` の形にし、enum は名前から値に変換して入れる。
- 属性名・参照名・enum 値を推測で書かない。分からないものは `dump_features.js` で実機の要素を調べ、確認した日付をヘッダーに書く。

## エラー
- スクリプトの途中で例外が出ると、medini はそのスクリプトでの変更をすべて取り消す（Scripting Doc 10 章）。中途半端な書き込みを防ぐ手段として使ってよい。
- 利用者に伝える中止理由は、既存どおり `throw "日本語のメッセージ"` で投げる。想定外の状態は `throw new Error("...")` にする。
- 空の `catch` は書かない。見た目の設定のように失敗しても続けてよい処理だけは例外とし、その理由をコメントに書く。
- `console.log` は `{0}` `{1}` の置き換え形式で書く。
