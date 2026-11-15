# Configuration Guidelines

> **[Replaceable]** This guide uses a **custom configuration resolver**. The same principles apply when using **cosmiconfig** or **c12** for configuration loading.

This document defines how to design configuration resolution, defaults, and validation for CLI tools.

---

## 1. Configuration Resolution Order

Configuration is resolved in priority order (higher number wins):

```text
1. Default values (hardcoded)
2. Configuration file (e.g., tool.config.json)
3. Environment variables
4. CLI arguments
```

```js
/** @param {CliOptions} cliOptions @returns {Config} */
function resolveConfig(cliOptions) {
  const fileConfig = loadConfigFile(cliOptions.config);
  return {
    ...DEFAULT_CONFIG,      // 1. Defaults
    ...fileConfig,          // 2. Config file
    ...envOverrides(),      // 3. Environment variables
    ...cliOverrides(cliOptions), // 4. CLI args (highest priority)
  };
}
```

---

## 2. Default Configuration

Define all defaults in a single, exported constant:

```js
/** @type {Readonly<Config>} */
export const DEFAULT_CONFIG = Object.freeze({
  outputDir: "./output",
  format: "md",
  lang: "en",
  verbose: false,
  pause: true,
  cacheEnabled: true,
  cacheTtl: "24h",
  workDir: ".work",
});
```

### Rules

- Every config field **must** have a default value
- Defaults should produce a **working configuration** with minimal user input
- Export `DEFAULT_CONFIG` for use in tests and documentation

---

## 3. Configuration File

## 3.1 File Format

Support JSON with comments (JSONC) for user-friendliness:

```jsonc
// tool.config.json
{
  "outputDir": "./reports",
  "format": "pdf",
  "modules": ["business", "ux", "competitor"],
  // Cache settings
  "cacheTtl": "48h"
}
```

## 3.2 File Discovery

Search for configuration files in standard locations:

```js
const CONFIG_FILE_NAMES = [
  "tool.config.json",
  ".toolrc.json",
  ".toolrc",
];
```

Or accept an explicit path via `--config <path>`.

## 3.3 Validation

Validate the configuration file with Zod (npm is available for Node.js tools). Type the result with `@typedef {import("zod").infer<typeof configSchema>} FileConfig`:

```js
const configSchema = z.object({
  outputDir: z.string().optional(),
  format: z.enum(["md", "json", "pdf"]).optional(),
  modules: z.array(z.string()).optional(),
  cacheTtl: z.string().regex(/^\d+(ms|s|m|h|d)$/).optional(),
});

const parsed = configSchema.safeParse(rawConfig);
if (!parsed.success) {
  throw new ConfigError(`Invalid config: ${parsed.error.message}`);
}
```

---

## 4. Environment Variables

## 4.1 Naming Convention

```text
{TOOL_NAME}_{SETTING} in SCREAMING_SNAKE_CASE
```

Example:

```bash
MY_TOOL_OUTPUT_DIR=./reports
MY_TOOL_VERBOSE=true
MY_TOOL_CACHE_TTL=48h
```

## 4.2 Implementation

```js
/** @returns {Partial<Config>} */
function envOverrides() {
  /** @type {Partial<Config>} */
  const env = {};
  if (process.env.MY_TOOL_OUTPUT_DIR) env.outputDir = process.env.MY_TOOL_OUTPUT_DIR;
  if (process.env.MY_TOOL_VERBOSE) env.verbose = process.env.MY_TOOL_VERBOSE === "true";
  return env;
}
```

---

## 5. Derived Configuration

Some values are computed from resolved configuration:

```js
/** @param {Config} config @returns {Config} */
function deriveConfig(config) {
  const hasUrl = Boolean(config.targetUrl);
  const hasSource = Boolean(config.sourceDir);
  const inputMode = hasUrl && hasSource ? "hybrid" : hasUrl ? "url" : "source";
  return Object.freeze({ ...config, inputMode });
}
```

---

## 6. Type Definitions

Define a single `Config` typedef (JSDoc) used throughout the application:

```js
// src/types/index.js
/**
 * Resolved tool configuration. Derived fields are set after resolution.
 * @typedef {Readonly<{
 *   targetUrl?: string,
 *   sourceDir?: string,
 *   inputMode: "url" | "source" | "hybrid",
 *   outputDir: string,
 *   format: "md" | "json" | "pdf",
 *   lang: string,
 *   verbose: boolean,
 *   pause: boolean,
 *   modules?: readonly string[],
 *   cacheEnabled: boolean,
 *   cacheTtl: string,
 *   workDir: string,
 * }>} Config
 */
```

### Rules

- Use a **single config type** — avoid splitting into multiple config objects
- Optional fields use `?` in the typedef — required fields have defaults
- Use **union types** for constrained values (not raw strings)

---

## 7. Summary

- **Resolution order: defaults → file → env → CLI** (CLI wins)
- **Every field has a default** — minimal input produces a working config
- **Validate config files with Zod** at load time
- **Derive computed values** after resolution
- **Single Config type** used throughout the application
- **Environment variables** follow `TOOL_NAME_SETTING` convention
