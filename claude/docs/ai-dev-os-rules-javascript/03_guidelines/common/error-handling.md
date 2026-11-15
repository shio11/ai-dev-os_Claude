# Error Handling Guidelines

This document defines error classification, display, and propagation for browser JavaScript that talks to a Python API.

## 1. Error Taxonomy

| Type | Examples | Handling |
|---|---|---|
| **System** | Python API 500, network failure, timeout, uncaught exception | Show a generic message with the next action; log to `console.error` |
| **Application** | Python API 400/409 (validation, domain rule), 404 | Show the message returned by Python (`detail`) |
| **User operation** | Missing input, double click, out-of-range value | Prevent in the UI (HTML attributes, disabled buttons) and show field-level messages |

## 2. Rules

* MUST NOT write an empty `catch`. Either handle (show / recover) or rethrow.
* MUST throw only `Error` or subclasses; never strings or plain objects.
* MUST keep the cause: `new Error("Failed to load stock", { cause: err })`.
* MUST treat `catch (err)` as `unknown` and narrow with `instanceof` before use.
* MUST define domain errors as subclasses when callers branch on them:

```js
export class ApiError extends Error {
  /** @param {string} message @param {number} status */
  constructor(message, status) { super(message); this.name = "ApiError"; this.status = status; }
}
```

* MUST NOT leave a Promise floating: `await` it, or attach `.catch()` that shows the error.

## 3. API Errors

* `api.js` MUST check `response.ok` and convert failures into `ApiError` carrying Python's `detail` message.
* Python returns user-facing messages; JS MUST NOT rewrite them into technical text.
* MUST NOT show stack traces or raw exception text to users.

## 4. Display (UI)

* MUST show user-facing errors **on the screen** in a fixed error area or next to the field — not only `alert()` or `console`.
* Field errors: next to the field, cleared when the value changes.
* Screen-level errors: one error area per screen (e.g. `<div role="alert">`).
* Initialization failure: `app.js` catches it and shows a screen-level error.

## 5. User-Facing Message Strategy

Each message addresses three points:

* **Specificity** — what failed, in user terms: 「品番の形式が正しくありません」, not 「Validation error」.
* **Action** — what to do next: 「確認して、もう一度保存してください」.
* **Impact** — what was affected: 「変更は保存されていません」.

Messages shown to users are in the team's language; JSDoc stays English.

## 6. Retry

* Automatic retry only for network failures and 502/503/504, at most 2 times with backoff.
* MUST NOT retry 400 / 403 / 404 / 409 or validation errors.
* MUST disable the submit button while a request is in flight to prevent double submission.

## 7. Graceful Degradation

* A failure in a non-essential part (side panel, summary) MUST NOT blank the whole screen; show a placeholder in that part.
