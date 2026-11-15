# Coding Standards & Static Analysis Guidelines

This guideline defines the **JavaScript coding standards** for code that runs without a build step: browser UI started from a Python app (frameworks/browser) and Node.js tools (frameworks/nodejs-cli). Types are written in JSDoc and checked by the TypeScript checker through `jsconfig.json` (`checkJs`), so the TypeScript rules carry over in JSDoc form.

## 1. Key Principles

* **Prioritize readability and maintainability** — write code that communicates intent, not the shortest code.
* **Enforce type safety with JSDoc** — every function, data shape and module constant has a JSDoc type; `checkJs` with `strict` reports zero errors.
* **Ensure quality through tooling** — `checkJs` always; ESLint / Prettier only when npm is available.

## 2. JavaScript Coding Standards

### 2.1 Type Definition Placement

* MUST put shared data shapes in `types.js` (or `types/`) as `@typedef`, next to their factory / guard functions.
* MUST type every function with `@param {Type}` and `@returns {Type}`; MUST type module-level constants with `@type` when inference is not exact.
* MUST mark data shapes read-only: `@typedef {Readonly<{ id: string, name: string }>} User`.
* `.d.ts` files are allowed only for global declarations (`globals.d.ts` for a classic-script namespace).

### 2.2 Handling Side Effects

* Functions with side effects MUST use verbs that signal I/O or mutation: `fetch`, `save`, `send`, `delete`, `upload`, `render`, `show`.
* Pure functions MUST use computational verbs: `calculate`, `format`, `parse`, `build`, `merge`, `validate`, `is` / `has`.
* MUST NOT use generic names (`handle`, `process`, `do`, `run`) for side-effecting functions unless the resource is named (`renderStockTable` ✅, `processData` ❌).
* Pure functions live in `lib`; DOM changes in `views`; network in `api` (see frameworks/browser/project-structure.md).

### 2.3 Minimize Type Casts

* MUST NOT write `{any}`, `{*}`, or `{Object}`. Receive unknown values as `{unknown}` and narrow with guard functions.
* MUST NOT cast with `/** @type {T} */ (value)` to silence errors. Allowed only right after a runtime check, or for `response.json()` → `unknown`.
* MUST NOT use `// @ts-ignore`. `// @ts-expect-error` is allowed only with a reason on the same line.

```js
// ❌ const name = /** @type {string} */ (form.get("name"));
// ✅ const name = form.get("name"); if (typeof name !== "string") throw new TypeError("name is missing");
```

### 2.4 No Enum-Like Classes → Union Literals + Frozen Objects

```js
/** @typedef {"dark" | "light"} Theme */
export const THEMES = Object.freeze(/** @type {const} */ (["dark", "light"]));
```

### 2.5 Exhaustive Checks on Union Types

MUST end every `switch` on a union type with `assertNever`, so `checkJs` reports a missing case:

```js
/** @param {never} value @returns {never} */
export function assertNever(value) { throw new Error(`Unhandled value: ${String(value)}`); }

/** @param {TaskStatus} status @returns {string} */
function formatStatusLabel(status) {
  switch (status) {
    case "TODO": return "未着手";
    case "DONE": return "完了";
    default: return assertNever(status);
  }
}
```

### 2.6 Immutability and Syntax

* MUST use `const`; `let` only when reassigned; never `var`.
* MUST NOT mutate arguments or shared data. Return new values (`map` / `filter` / spread / `toSorted` / `toSpliced` / `with`).
* MUST use `===` / `!==` only, and `??` / `?.` instead of `||` for defaults.
* MUST name magic numbers and strings as `UPPER_SNAKE_CASE` constants.
* MUST use named `export` only (no `export default`) in ESM.

## 3. Lint Standards (only when npm is available — always for Node.js tools)

* ESLint flat config with at least: `eqeqeq`, `no-var`, `prefer-const`, `no-unused-vars`, `no-empty`, `no-eval`, `no-implied-eval`, `no-new-func`, `no-throw-literal`, `require-await`, `no-console` (warn).
* Import order in ESM: external (`static/lib`) → internal (`types` → `lib` → `api` → `views`).
* Without npm, `checkJs` and `/ai-dev-os-check` are the gate.

## 4. Comment Standards

* Do not use comments to explain logic; document intent, side effects, and exceptional conditions only.
* JSDoc descriptions MUST be English (ASCII-only); `//` line comments may use the team's native language.
* Full rules: [`comment-format.md`](./comment-format.md).

## 5. Code Reuse

| Condition | Action |
|---|---|
| Same logic in 2+ places | Extract a helper in `lib` |
| Same pattern in 3+ places | Extract a factory / builder function |
| Network calls | Only through the shared `request()` in `api.js` |
| DOM lookups of required elements | One helper that throws with the element name when missing |

* MUST NOT abstract code used in only one place, or add options "for the future".
