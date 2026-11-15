# Testing Guidelines

This document defines testing for browser JavaScript started from a Python app (sections 1–5) and for Node.js tools (section 6).

## 1. Core Policy

* Critical logic (calculations, decisions, data integrity) lives in Python and is tested there.
* Screens are verified by **E2E tests started from pytest** (Playwright for Python): start the app, open the screen, operate it, assert what the user sees.
* E2E covers only flows where a failure blocks the user or corrupts data (load, save, main operations, error display).
* MUST NOT delete or comment out existing tests without confirmation.

## 2. Pure Functions and Guards

* `lib` functions and `types` guard / factory functions MUST stay free of DOM and network so they can be tested alone.
* Test them from pytest with Playwright's `page.evaluate()` importing the module, or with `node --test` when Node.js is available.
* Each guard function needs at least one valid and one invalid case.

## 3. Rules Implemented on Both Sides

* When the same rule exists in Python and JS (e.g. a single HTML opened from `file://` with logic in JS), MUST add a comparison test that runs the same inputs through both and asserts equal results.

## 4. Error Scenarios

* For each screen, test at least: API failure shows the error area, invalid input shows a field message, double click does not submit twice.

## 5. Naming and Layout

* Test names in English. Place E2E tests with the Python tests (e.g. `tests/e2e/test_<screen>.py`).

## 6. Node.js Tools

* Use the built-in test runner: `node --test`, `import { test } from "node:test"`, `import assert from "node:assert/strict"`.
* Co-locate unit tests as `{module}.test.js`; E2E tests in `tests/e2e/` run the CLI with `node:child_process` and assert stdout / stderr / exit code.
* Each module's error paths (invalid input, missing file, external failure) need at least one test.
