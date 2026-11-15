# Validation Guidelines

This document defines how types and validation are managed in JavaScript.

* **Browser UI** (no npm): no schema library — use guard / factory functions as below.
* **Node.js tools** (npm available): Zod MAY be used for config files and external input; type its output with `@typedef {import("zod").infer<typeof Schema>} Name`. The boundary rules below still apply.

## 1. Core Policy

* **Python is the source of truth** for business rules and validation. JS validation exists for instant feedback and for protecting the screen from malformed data.
* MUST validate every untrusted value **at the boundary where it enters JS**: API responses, embedded JSON, form values, URL parameters, `localStorage`, `postMessage`.
* MUST validate with a **guard function** (`isStockItem(value)`) and build internal values with a **factory function** (`createStockItem(...)`) that throws `RangeError` / `TypeError` on invalid input and returns an `Object.freeze`d object.
* MUST NOT pass unvalidated data from `api` to `views`.

```js
/** @param {unknown} value @returns {value is StockItem} */
export function isStockItem(value) {
  return typeof value === "object" && value !== null
    && "partNo" in value && typeof value.partNo === "string"
    && "quantity" in value && Number.isInteger(value.quantity);
}
```

## 2. What to Check in JS

* Format and range checks that give instant feedback (required, length, number range, pattern) — prefer HTML attributes (`required`, `min`, `max`, `maxlength`, `pattern`) first, then JS.
* Conditional required fields that change the form UI.
* MUST NOT implement checks that need data the browser does not own (duplicates, stock availability, permissions) — call Python.
* When a rule exists in both Python and JS, keep the same limits as named constants and add a test that compares both (see testing.md).

## 3. Types Shared with Python

* `types.js` typedefs MUST map 1:1 to the Python models (Pydantic / dataclass) — same field names, same optionality.
* When the Python model changes, update `types.js` and its guard in the same change.
* Dates: ISO 8601 strings. Date-only values (`YYYY-MM-DD`) stay strings; do not convert them with `new Date()`.

## 4. Before/After

```js
// ❌ const items = await response.json(); renderStock(items);
// ✅ const body = await request("/api/stock"); if (!Array.isArray(body) || !body.every(isStockItem)) throw new TypeError("Invalid stock response"); renderStock(body);
```
