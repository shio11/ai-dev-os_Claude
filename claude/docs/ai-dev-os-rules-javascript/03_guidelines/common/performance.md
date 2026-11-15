# Performance Guidelines

This document defines performance rules for browser JavaScript without a build step.

## 1. Loading

* Keep vendored libraries minimal; SHOULD NOT add a library over ~100 KB minified for a feature that native APIs cover (`Intl`, `fetch`, `structuredClone`, `<dialog>`).
* ESM: load screen modules only when the screen is opened (`await import("./views/<screen>.js")`) when there are 3+ screens.

## 2. DOM Updates

* SHOULD build large lists in a `DocumentFragment` and attach once.
* SHOULD use event delegation on a parent instead of one listener per row.
* MUST remove listeners of re-rendered parts with an `AbortController` signal.
* SHOULD paginate or virtualize tables with more than ~1,000 rows.

## 3. Network

* Run independent requests in parallel with `Promise.all`.
* Debounce search / filter inputs (~300 ms) before calling the API.
* Do not refetch data that has not changed; keep the last successful response for redisplay.

## 4. CPU

* Move heavy processing (large file parsing, Excel generation) to Python when possible; otherwise to a Web Worker.
* Avoid repeated `JSON.parse(JSON.stringify(x))`; use `structuredClone` for plain data.

## 5. Measurement

* Measure with the browser Performance panel before optimizing; do not optimize without a measured problem.
