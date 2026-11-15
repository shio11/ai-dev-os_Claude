# Naming Convention Guidelines

This document defines naming conventions for browser JavaScript started from a Python app.

## 1. General Principles

* Unify naming within each module; do not mix conventions.
* **Variables/fields**: 1–3 words, max 30 characters (`createdAt`, `orderItemCount`).
* **Functions**: verb + noun, 2–4 words, max 40 characters (`fetchStockItems`, `formatPartNumber`).
* **Typedefs**: 1–3 words describing the shape (`StockItem`, `OrderSummary`).
* Avoid abbreviations except universal ones (`id`, `url`, `api`, `db`, `html`); ❌ `usr`, `msg`, `btn`, `cfg`.
* A name over the limits signals the concept should be split.

## 2. Identifiers

| Target | Convention | Example |
|---|---|---|
| Variable / function | camelCase | `selectedRows`, `renderStockTable` |
| Class / `@typedef` | PascalCase | `StockTableState`, `StockItem` |
| Constant / frozen enum object | UPPER_SNAKE_CASE | `TIMEOUT_MS`, `ORDER_STATUS` |
| Boolean | `is` / `has` / `can` prefix | `isLoading`, `hasError` |
| Private field | `#name` (never `_name`) | `#rows` |
| Factory function | `create` + typedef name | `createStockItem` |
| Guard function | `is` + typedef name | `isStockItem` |

## 3. Event Handlers

* MUST use `handle` + noun + verb: `handleTaskDelete`, `handleFormSubmit` (❌ `handleClick`, `onSubmit`).
* Callbacks passed into view builders use the `on` prefix: `onTaskDelete`.

## 4. Files and Folders

* MUST use lowercase kebab-case file names: `stock-table.js`, `globals.d.ts`.
* Layer files and folders use the fixed names `app.js`, `api`, `types`, `lib`, `views` (see frameworks/browser/project-structure.md).
* Screen modules: `views/<screen-name>.js`.
* Vendored libraries keep their version in the name: `static/lib/exceljs-4.4.0.min.js`.

## 5. DOM and API

* `id` / `class` / `data-*` attributes: kebab-case (`data-part-no`); read via `dataset.partNo`.
* JSON fields exchanged with Python MUST match the Python model field names exactly; convert snake_case ↔ camelCase in one place (`types.js` factories) if the two sides differ.
* API paths come from Python; JS MUST NOT invent paths — keep them as constants in `api.js`.
