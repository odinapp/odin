# Cloudflare Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a self-contained Cloudflare Workers backend (`odin-worker/`) that replaces `getodin.com`, storing files for 24 hours with built-in short-URL tokens and per-upload delete URLs.

**Architecture:** A single Cloudflare Worker handles all API endpoints. Files are stored in R2; upload metadata is stored in KV with a 24h TTL for automatic logical expiry. A separate KV key per upload (`cleanup:<token>`) feeds a cron-triggered Worker that physically deletes R2 objects after expiry.

**Tech Stack:** TypeScript, Cloudflare Workers, Cloudflare R2, Cloudflare KV, `fflate` (WASM-free zip), `vitest` + `@cloudflare/vitest-pool-workers` (tests), `wrangler` (CLI)

---

## File Map

| File | Status | Responsibility |
|------|--------|----------------|
| `odin-worker/wrangler.toml` | Create | Wrangler config: bindings, cron trigger, PUBLIC_URL var |
| `odin-worker/package.json` | Create | Dependencies: fflate, wrangler, vitest, @cloudflare/vitest-pool-workers |
| `odin-worker/tsconfig.json` | Create | TypeScript config for Workers runtime |
| `odin-worker/vitest.config.ts` | Create | Test runner config using Workers pool |
| `odin-worker/src/types.ts` | Create | `Env` interface (R2_BUCKET, KV_METADATA, PUBLIC_URL) |
| `odin-worker/src/lib/response.ts` | Create | `jsonError()` helper |
| `odin-worker/src/lib/token.ts` | Create | `randomString()`, `generateToken()` (collision-safe) |
| `odin-worker/src/lib/zip.ts` | Create | `zipFiles()` using fflate |
| `odin-worker/src/lib/kv.ts` | Create | KV read/write/delete helpers, cleanup index management |
| `odin-worker/src/handlers/config.ts` | Create | `GET /api/v1/config/` — static JSON response |
| `odin-worker/src/handlers/info.ts` | Create | `GET /api/v1/file/info/` — lookup KV, return FilesMetadata shape |
| `odin-worker/src/handlers/download.ts` | Create | `GET /api/v1/file/download/` — stream R2 bytes |
| `odin-worker/src/handlers/redirect.ts` | Create | `GET /d/:token` — browser short URL, serves file directly |
| `odin-worker/src/handlers/delete.ts` | Create | `GET+DELETE /delete/:token` — validate secret, remove R2+KV |
| `odin-worker/src/handlers/upload.ts` | Create | `POST /api/v1/file/upload/` — accept files, zip, R2 put, KV write |
| `odin-worker/src/cron.ts` | Create | Hourly cleanup: list `cleanup:*` keys, delete expired R2 objects |
| `odin-worker/src/index.ts` | Create | Router — dispatches all requests to handlers |
| `odin-worker/src/__tests__/token.test.ts` | Create | Unit tests for token generation |
| `odin-worker/src/__tests__/zip.test.ts` | Create | Unit tests for zip helper |
| `odin-worker/src/__tests__/kv.test.ts` | Create | Unit tests for KV helpers |
| `odin-worker/src/__tests__/config.test.ts` | Create | Handler test: config returns correct shape |
| `odin-worker/src/__tests__/upload.test.ts` | Create | Handler test: upload, validation, R2/KV writes |
| `odin-worker/src/__tests__/info.test.ts` | Create | Handler test: info lookup, 404 on missing token |
| `odin-worker/src/__tests__/download.test.ts` | Create | Handler test: download streams bytes, correct headers |
| `odin-worker/src/__tests__/delete.test.ts` | Create | Handler test: delete validates secret, cleans up |
| `odin-worker/src/__tests__/cron.test.ts` | Create | Cron test: expired entries deleted, fresh entries kept |
| `.env` (Flutter) | Modify | Update API_URL to point to deployed Worker |

All paths are relative to `/home/codenameakshay/Development/codenameakshay/odin/`.

---

## Task 1: Scaffold the project

**Files:**
- Create: `odin-worker/wrangler.toml`
- Create: `odin-worker/package.json`
- Create: `odin-worker/tsconfig.json`
- Create: `odin-worker/vitest.config.ts`
- Create: `odin-worker/src/types.ts`
- Create: `odin-worker/src/lib/response.ts`

- [ ] **Step 1: Create the odin-worker directory and package.json**

```bash
mkdir -p /home/codenameakshay/Development/codenameakshay/odin/odin-worker/src/handlers
mkdir -p /home/codenameakshay/Development/codenameakshay/odin/odin-worker/src/lib
mkdir -p /home/codenameakshay/Development/codenameakshay/odin/odin-worker/src/__tests__
```

Create `odin-worker/package.json`:
```json
{
  "name": "odin-worker",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "fflate": "^0.8.2"
  },
  "devDependencies": {
    "@cloudflare/vitest-pool-workers": "^0.8.0",
    "@cloudflare/workers-types": "^4.20250321.0",
    "typescript": "^5.4.5",
    "vitest": "^2.0.0",
    "wrangler": "^3.114.0"
  }
}
```

- [ ] **Step 2: Create wrangler.toml**

Create `odin-worker/wrangler.toml`:
```toml
name = "odin-worker"
main = "src/index.ts"
compatibility_date = "2025-03-24"
compatibility_flags = ["nodejs_compat"]

[vars]
PUBLIC_URL = "https://odin-worker.workers.dev"

[[r2_buckets]]
binding = "R2_BUCKET"
bucket_name = "odin-files"
preview_bucket_name = "odin-files-preview"

[[kv_namespaces]]
binding = "KV_METADATA"
id = "REPLACE_WITH_KV_NAMESPACE_ID"
preview_id = "REPLACE_WITH_KV_PREVIEW_ID"

[triggers]
crons = ["0 * * * *"]
```

> **Note:** After running `wrangler kv namespace create odin-metadata`, replace `REPLACE_WITH_KV_NAMESPACE_ID` and `REPLACE_WITH_KV_PREVIEW_ID` with the real IDs from the output.

- [ ] **Step 3: Create tsconfig.json**

Create `odin-worker/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 4: Create vitest.config.ts**

Create `odin-worker/vitest.config.ts`:
```typescript
import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: './wrangler.toml' },
        miniflare: {
          kvNamespaces: ['KV_METADATA'],
          r2Buckets: ['R2_BUCKET'],
          bindings: {
            PUBLIC_URL: 'https://odin-worker.workers.dev',
          },
        },
      },
    },
  },
});
```

- [ ] **Step 5: Create src/types.ts**

Create `odin-worker/src/types.ts`:
```typescript
export interface Env {
  R2_BUCKET: R2Bucket;
  KV_METADATA: KVNamespace;
  PUBLIC_URL: string;
}
```

- [ ] **Step 6: Create src/lib/response.ts**

Create `odin-worker/src/lib/response.ts`:
```typescript
export function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}
```

- [ ] **Step 7: Install dependencies**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm install
```

Expected: `node_modules/` created, no errors.

- [ ] **Step 8: Commit scaffold**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/
git commit -m "feat: scaffold odin-worker project"
```

---

## Task 2: lib/token.ts — token generation

**Files:**
- Create: `odin-worker/src/lib/token.ts`
- Create: `odin-worker/src/__tests__/token.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/token.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { randomString, generateToken, extractTokenCode } from '../lib/token';

describe('randomString', () => {
  it('returns a string of the requested length', () => {
    expect(randomString(8)).toHaveLength(8);
    expect(randomString(16)).toHaveLength(16);
  });

  it('only contains alphanumeric characters', () => {
    const s = randomString(100);
    expect(s).toMatch(/^[A-Za-z0-9]+$/);
  });

  it('produces statistically unique outputs across 1000 calls', () => {
    const results = new Set(Array.from({ length: 1000 }, () => randomString(8)));
    // With 62^8 ≈ 218 trillion possibilities, 1000 calls must all be unique
    expect(results.size).toBe(1000);
  });
});

describe('generateToken', () => {
  it('returns an 8-char token when KV has no collision', async () => {
    const token = await generateToken(env.KV_METADATA);
    expect(token).toHaveLength(8);
    expect(token).toMatch(/^[A-Za-z0-9]{8}$/);
  });

  it('retries and succeeds when the first two attempts collide', async () => {
    // Pre-seed two specific tokens as collisions
    await env.KV_METADATA.put('aaaaaaaa', 'taken');
    await env.KV_METADATA.put('bbbbbbbb', 'taken');
    // Inject a deterministic candidate sequence: first two collide, third succeeds
    const candidates = ['aaaaaaaa', 'bbbbbbbb', 'cccccccc'];
    let i = 0;
    const token = await generateToken(env.KV_METADATA, () => candidates[i++]);
    expect(token).toBe('cccccccc');
  });

  it('throws after 3 consecutive collisions', async () => {
    await env.KV_METADATA.put('dddddddd', 'taken');
    await env.KV_METADATA.put('eeeeeeee', 'taken');
    await env.KV_METADATA.put('ffffffff', 'taken');
    const candidates = ['dddddddd', 'eeeeeeee', 'ffffffff'];
    let i = 0;
    await expect(generateToken(env.KV_METADATA, () => candidates[i++])).rejects.toThrow();
  });
});

describe('extractTokenCode', () => {
  it('extracts 8-char code from a full /d/ URL', () => {
    expect(extractTokenCode('https://odin-worker.workers.dev/d/aB3kR9mQ')).toBe('aB3kR9mQ');
  });

  it('returns the input unchanged when already a bare code', () => {
    expect(extractTokenCode('aB3kR9mQ')).toBe('aB3kR9mQ');
  });

  it('handles URLs with trailing slash', () => {
    expect(extractTokenCode('https://odin-worker.workers.dev/d/aB3kR9mQ/')).toBe('aB3kR9mQ');
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- token
```

Expected: FAIL — `../lib/token` module not found.

- [ ] **Step 3: Implement src/lib/token.ts**

Create `odin-worker/src/lib/token.ts`:
```typescript
const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

export function randomString(length: number): string {
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  return Array.from(bytes).map(b => CHARS[b % CHARS.length]).join('');
}

/**
 * Generates a unique token by checking KV for collisions.
 * Retries up to 3 times; throws if all retries collide (astronomically unlikely).
 *
 * @param generateCandidate - Optional injectable for testing; defaults to randomString(length).
 */
export async function generateToken(
  kv: KVNamespace,
  generateCandidate?: () => string,
  length = 8,
): Promise<string> {
  const candidate = generateCandidate ?? (() => randomString(length));
  for (let i = 0; i < 3; i++) {
    const token = candidate();
    const existing = await kv.get(token);
    if (existing === null) return token;
  }
  throw new Error('Token collision after 3 retries');
}

/**
 * Extracts the 8-char token code from either:
 * - A full URL: https://odin-worker.workers.dev/d/aB3kR9mQ → aB3kR9mQ
 * - A bare code: aB3kR9mQ → aB3kR9mQ
 */
export function extractTokenCode(tokenOrUrl: string): string {
  try {
    const url = new URL(tokenOrUrl);
    const segments = url.pathname.split('/').filter(Boolean);
    const dIndex = segments.indexOf('d');
    if (dIndex !== -1 && segments[dIndex + 1]) {
      return segments[dIndex + 1];
    }
  } catch {
    // Not a URL — use as-is
  }
  return tokenOrUrl;
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- token
```

Expected: PASS — all 5 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/lib/token.ts odin-worker/src/__tests__/token.test.ts
git commit -m "feat: add token generation and extraction helpers"
```

---

## Task 3: lib/zip.ts — multi-file zip

**Files:**
- Create: `odin-worker/src/lib/zip.ts`
- Create: `odin-worker/src/__tests__/zip.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/zip.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { zipFiles } from '../lib/zip';
// fflate can unzip for verification
import { unzipSync } from 'fflate';

describe('zipFiles', () => {
  it('returns a Uint8Array for a single file', () => {
    const result = zipFiles([{ name: 'hello.txt', data: new TextEncoder().encode('hello') }]);
    expect(result).toBeInstanceOf(Uint8Array);
    expect(result.length).toBeGreaterThan(0);
  });

  it('produces a valid zip containing all files', () => {
    const files = [
      { name: 'a.txt', data: new TextEncoder().encode('file a') },
      { name: 'b.txt', data: new TextEncoder().encode('file b') },
    ];
    const zipped = zipFiles(files);
    const unzipped = unzipSync(zipped);
    expect(Object.keys(unzipped)).toContain('a.txt');
    expect(Object.keys(unzipped)).toContain('b.txt');
    expect(new TextDecoder().decode(unzipped['a.txt'])).toBe('file a');
    expect(new TextDecoder().decode(unzipped['b.txt'])).toBe('file b');
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- zip
```

Expected: FAIL — `../lib/zip` module not found.

- [ ] **Step 3: Implement src/lib/zip.ts**

Create `odin-worker/src/lib/zip.ts`:
```typescript
import { zipSync } from 'fflate';

export interface FileEntry {
  name: string;
  data: Uint8Array;
}

export function zipFiles(files: FileEntry[]): Uint8Array {
  const input: Record<string, Uint8Array> = {};
  for (const file of files) {
    input[file.name] = file.data;
  }
  return zipSync(input);
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- zip
```

Expected: PASS — all 2 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/lib/zip.ts odin-worker/src/__tests__/zip.test.ts
git commit -m "feat: add multi-file zip helper using fflate"
```

---

## Task 4: lib/kv.ts — KV helpers

**Files:**
- Create: `odin-worker/src/lib/kv.ts`
- Create: `odin-worker/src/__tests__/kv.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/kv.test.ts`:
```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { env } from 'cloudflare:test';
import {
  setMetadata, getMetadata, deleteMetadata,
  setCleanupEntry, deleteCleanupEntry, listCleanupEntries,
  type UploadMetadata, type CleanupEntry,
} from '../lib/kv';

const SAMPLE_META: UploadMetadata = {
  r2Key: 'abc12345/file.txt',
  filename: 'file.txt',
  size: 1234,
  uploadedAt: '2026-03-24T00:00:00.000Z',
  expiresAt: '2026-03-25T00:00:00.000Z',
  deleteToken: 'xxxxxxxxxxxxxxxx',
};

const SAMPLE_CLEANUP: CleanupEntry = {
  token: 'abc12345',
  r2Key: 'abc12345/file.txt',
  expiresAt: '2026-03-25T00:00:00.000Z',
};

describe('metadata helpers', () => {
  beforeEach(async () => {
    await env.KV_METADATA.delete('kv00001');
    await env.KV_METADATA.delete('kv00002');
  });

  it('returns null for missing key', async () => {
    expect(await getMetadata(env.KV_METADATA, 'missing')).toBeNull();
  });

  it('round-trips metadata through KV', async () => {
    await setMetadata(env.KV_METADATA, 'kv00001', SAMPLE_META);
    const result = await getMetadata(env.KV_METADATA, 'kv00001');
    expect(result).toEqual(SAMPLE_META);
  });

  it('deletes metadata', async () => {
    await setMetadata(env.KV_METADATA, 'kv00002', SAMPLE_META);
    await deleteMetadata(env.KV_METADATA, 'kv00002');
    expect(await getMetadata(env.KV_METADATA, 'kv00002')).toBeNull();
  });
});

describe('cleanup index helpers', () => {
  beforeEach(async () => {
    await env.KV_METADATA.delete('cleanup:kv00003');
    await env.KV_METADATA.delete('cleanup:kv00004');
  });

  it('lists cleanup entries by prefix', async () => {
    await setCleanupEntry(env.KV_METADATA, 'kv00003', { ...SAMPLE_CLEANUP, token: 'kv00003' });
    const entries = await listCleanupEntries(env.KV_METADATA);
    expect(entries.some(e => e.token === 'kv00003')).toBe(true);
  });

  it('deletes cleanup entry', async () => {
    await setCleanupEntry(env.KV_METADATA, 'kv00004', { ...SAMPLE_CLEANUP, token: 'kv00004' });
    await deleteCleanupEntry(env.KV_METADATA, 'kv00004');
    const entries = await listCleanupEntries(env.KV_METADATA);
    expect(entries.some(e => e.token === 'kv00004')).toBe(false);
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- kv
```

Expected: FAIL — `../lib/kv` module not found.

- [ ] **Step 3: Implement src/lib/kv.ts**

Create `odin-worker/src/lib/kv.ts`:
```typescript
export interface UploadMetadata {
  r2Key: string;
  filename: string;
  size: number;
  uploadedAt: string;
  expiresAt: string;
  deleteToken: string;
}

export interface CleanupEntry {
  token: string;
  r2Key: string;
  expiresAt: string;
}

export async function getMetadata(kv: KVNamespace, token: string): Promise<UploadMetadata | null> {
  const value = await kv.get(token);
  if (value === null) return null;
  return JSON.parse(value) as UploadMetadata;
}

export async function setMetadata(
  kv: KVNamespace,
  token: string,
  metadata: UploadMetadata,
): Promise<void> {
  await kv.put(token, JSON.stringify(metadata), { expirationTtl: 86400 });
}

export async function deleteMetadata(kv: KVNamespace, token: string): Promise<void> {
  await kv.delete(token);
}

export async function setCleanupEntry(
  kv: KVNamespace,
  token: string,
  entry: CleanupEntry,
): Promise<void> {
  await kv.put(`cleanup:${token}`, JSON.stringify(entry), { expirationTtl: 172800 });
}

export async function deleteCleanupEntry(kv: KVNamespace, token: string): Promise<void> {
  await kv.delete(`cleanup:${token}`);
}

export async function listCleanupEntries(kv: KVNamespace): Promise<CleanupEntry[]> {
  const list = await kv.list({ prefix: 'cleanup:' });
  const entries: CleanupEntry[] = [];
  for (const key of list.keys) {
    const value = await kv.get(key.name);
    if (value !== null) {
      entries.push(JSON.parse(value) as CleanupEntry);
    }
  }
  return entries;
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- kv
```

Expected: PASS — all 5 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/lib/kv.ts odin-worker/src/__tests__/kv.test.ts
git commit -m "feat: add KV metadata and cleanup index helpers"
```

---

## Task 5: handlers/config.ts

**Files:**
- Create: `odin-worker/src/handlers/config.ts`
- Create: `odin-worker/src/__tests__/config.test.ts`

- [ ] **Step 1: Write failing test**

Create `odin-worker/src/__tests__/config.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleConfig } from '../handlers/config';

describe('GET /api/v1/config/', () => {
  it('returns 200 with all required fields and exact string values', async () => {
    const req = new Request('https://example.com/api/v1/config/');
    const res = await handleConfig(req, env);
    expect(res.status).toBe(200);

    const body = await res.json() as Record<string, unknown>;

    // home — exact values consumed by Flutter HomeConfig deserialiser
    const home = body.home as Record<string, string>;
    expect(home.title).toBe('Odin');
    expect(home.primaryButtonText).toBe('Send files');
    expect(home.secondaryButtonText).toBe('Receive files');

    // upload — exact values consumed by Flutter UploadConfig deserialiser (7 required fields)
    const upload = body.upload as Record<string, string>;
    expect(upload.title).toBe('Uploading');
    expect(upload.description).toBe('Your files are being uploaded');
    expect(upload.backButtonText).toBe('Back');
    expect(upload.cancelDefaultText).toBe('Cancel');
    expect(upload.errorButtonText).toBe('Retry');
    expect(upload.errorDefaultText).toBe('Upload failed');
    expect(upload.successDefaultText).toBe('Upload complete');

    // token — exact values consumed by Flutter TokenConfig deserialiser (5 required fields)
    const token = body.token as Record<string, string>;
    expect(token.title).toBe('Receive files');
    expect(token.description).toBe('Enter the token to download your files');
    expect(token.textFieldHintText).toBe('Enter token');
    expect(token.backButtonText).toBe('Back');
    expect(token.primaryButtonText).toBe('Download');
  });
});
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- config
```

Expected: FAIL — `../handlers/config` not found.

- [ ] **Step 3: Implement src/handlers/config.ts**

Create `odin-worker/src/handlers/config.ts`:
```typescript
import type { Env } from '../types';

const CONFIG = {
  home: {
    title: 'Odin',
    primaryButtonText: 'Send files',
    secondaryButtonText: 'Receive files',
  },
  upload: {
    title: 'Uploading',
    description: 'Your files are being uploaded',
    backButtonText: 'Back',
    cancelDefaultText: 'Cancel',
    errorButtonText: 'Retry',
    errorDefaultText: 'Upload failed',
    successDefaultText: 'Upload complete',
  },
  token: {
    title: 'Receive files',
    description: 'Enter the token to download your files',
    textFieldHintText: 'Enter token',
    backButtonText: 'Back',
    primaryButtonText: 'Download',
  },
};

export function handleConfig(_req: Request, _env: Env): Response {
  return Response.json(CONFIG);
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- config
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/handlers/config.ts odin-worker/src/__tests__/config.test.ts
git commit -m "feat: add config handler with all required Flutter model fields"
```

---

## Task 6: handlers/upload.ts

**Files:**
- Create: `odin-worker/src/handlers/upload.ts`
- Create: `odin-worker/src/__tests__/upload.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/upload.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleUpload } from '../handlers/upload';

function makeUploadRequest(files: { name: string; content: string; fieldName?: string }[]): Request {
  const form = new FormData();
  for (const f of files) {
    form.append(f.fieldName ?? 'file', new File([f.content], f.name));
  }
  form.append('directoryName', 'testdir');
  form.append('totalFileSize', String(files.reduce((s, f) => s + f.content.length, 0)));
  return new Request('https://odin-worker.workers.dev/api/v1/file/upload/', {
    method: 'POST',
    body: form,
  });
}

describe('POST /api/v1/file/upload/', () => {
  it('returns 400 when no file field is present', async () => {
    const form = new FormData();
    form.append('directoryName', 'x');
    const req = new Request('https://example.com/api/v1/file/upload/', { method: 'POST', body: form });
    const res = await handleUpload(req, env);
    expect(res.status).toBe(400);
  });

  it('returns 413 when totalFileSize exceeds 100 MB (checked before reading bytes)', async () => {
    const form = new FormData();
    // Small file but declared size exceeds limit — handler must reject on declared size
    form.append('file', new File(['tiny'], 'tiny.txt'));
    form.append('directoryName', 'x');
    form.append('totalFileSize', String(101 * 1024 * 1024)); // 101 MB declared
    const req = new Request('https://example.com/api/v1/file/upload/', { method: 'POST', body: form });
    const res = await handleUpload(req, env);
    expect(res.status).toBe(413);
  });

  it('returns token and deleteToken on valid single-file upload (file field)', async () => {
    const req = makeUploadRequest([{ name: 'hello.txt', content: 'hello world' }]);
    const res = await handleUpload(req, env);
    expect(res.status).toBe(200);
    const body = await res.json() as { token: string; deleteToken: string };
    expect(body.token).toMatch(/\/d\/[A-Za-z0-9]{8}$/);
    expect(body.deleteToken).toMatch(/\/delete\/[A-Za-z0-9]{8}\?secret=[A-Za-z0-9]{16}$/);
  });

  it('accepts the "media" field name (single-file path)', async () => {
    const req = makeUploadRequest([{ name: 'doc.pdf', content: 'pdf-bytes', fieldName: 'media' }]);
    const res = await handleUpload(req, env);
    expect(res.status).toBe(200);
  });

  it('stores file in R2', async () => {
    const req = makeUploadRequest([{ name: 'test.txt', content: 'r2 content' }]);
    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    // Extract token code from URL
    const code = body.token.split('/d/')[1];
    const r2Object = await env.R2_BUCKET.get(`${code}/test.txt`);
    expect(r2Object).not.toBeNull();
  });

  it('stores metadata in KV', async () => {
    const req = makeUploadRequest([{ name: 'meta.txt', content: 'kv test' }]);
    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    const code = body.token.split('/d/')[1];
    const meta = await env.KV_METADATA.get(code);
    expect(meta).not.toBeNull();
    const parsed = JSON.parse(meta!);
    expect(parsed.filename).toBe('meta.txt');
    expect(parsed.deleteToken).toHaveLength(16);
  });

  it('zips multiple files and names the upload files.zip', async () => {
    const req = makeUploadRequest([
      { name: 'a.txt', content: 'aaa' },
      { name: 'b.txt', content: 'bbb' },
    ]);
    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    const code = body.token.split('/d/')[1];
    const meta = await env.KV_METADATA.get(code);
    expect(JSON.parse(meta!).filename).toBe('files.zip');
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- upload
```

Expected: FAIL — `../handlers/upload` not found.

- [ ] **Step 3: Implement src/handlers/upload.ts**

Create `odin-worker/src/handlers/upload.ts`:
```typescript
import type { Env } from '../types';
import { generateToken, randomString } from '../lib/token';
import { setMetadata, setCleanupEntry } from '../lib/kv';
import { zipFiles } from '../lib/zip';
import { jsonError } from '../lib/response';

const MAX_BYTES = 100 * 1024 * 1024;

export async function handleUpload(req: Request, env: Env): Promise<Response> {
  const contentType = req.headers.get('content-type') ?? '';
  if (!contentType.includes('multipart/form-data')) {
    return jsonError(400, 'no file provided');
  }

  let formData: FormData;
  try {
    formData = await req.formData();
  } catch {
    return jsonError(400, 'invalid multipart data');
  }

  // Reject early on declared size before reading any bytes into memory
  const declaredSize = parseInt(formData.get('totalFileSize') as string ?? '0', 10);
  if (!isNaN(declaredSize) && declaredSize > MAX_BYTES) {
    return jsonError(413, 'file too large');
  }

  // Collect files from both 'file' (multi-file path) and 'media' (single-file path)
  const fileEntries: { name: string; data: Uint8Array }[] = [];
  for (const [key, value] of formData.entries()) {
    if ((key === 'file' || key === 'media') && value instanceof File) {
      const buf = await value.arrayBuffer();
      fileEntries.push({ name: value.name, data: new Uint8Array(buf) });
    }
  }

  if (fileEntries.length === 0) {
    return jsonError(400, 'no file provided');
  }

  // Secondary check on actual bytes (guards against mismatched totalFileSize)
  const totalBytes = fileEntries.reduce((sum, f) => sum + f.data.length, 0);
  if (totalBytes > MAX_BYTES) {
    return jsonError(413, 'file too large');
  }

  const finalData = fileEntries.length === 1
    ? fileEntries[0].data
    : zipFiles(fileEntries);
  const finalName = fileEntries.length === 1
    ? fileEntries[0].name
    : 'files.zip';

  let token: string;
  try {
    token = await generateToken(env.KV_METADATA); // uses default randomString candidate
  } catch {
    return jsonError(500, 'storage error');
  }

  const r2Key = `${token}/${finalName}`;
  const deleteToken = randomString(16);
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 86400 * 1000);

  try {
    await env.R2_BUCKET.put(r2Key, finalData);
  } catch {
    return jsonError(500, 'storage error');
  }

  try {
    await setMetadata(env.KV_METADATA, token, {
      r2Key,
      filename: finalName,
      size: finalData.length,
      uploadedAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      deleteToken,
    });
    await setCleanupEntry(env.KV_METADATA, token, {
      token,
      r2Key,
      expiresAt: expiresAt.toISOString(),
    });
  } catch {
    return jsonError(500, 'storage error');
  }

  return Response.json({
    token: `${env.PUBLIC_URL}/d/${token}`,
    deleteToken: `${env.PUBLIC_URL}/delete/${token}?secret=${deleteToken}`,
  });
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- upload
```

Expected: PASS — all 6 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/handlers/upload.ts odin-worker/src/__tests__/upload.test.ts
git commit -m "feat: add upload handler with R2 storage and KV metadata"
```

---

## Task 7: handlers/info.ts

**Files:**
- Create: `odin-worker/src/handlers/info.ts`
- Create: `odin-worker/src/__tests__/info.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/info.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleInfo } from '../handlers/info';
import { setMetadata } from '../lib/kv';
import type { UploadMetadata } from '../lib/kv';

const SAMPLE: UploadMetadata = {
  r2Key: 'tok00001/file.txt',
  filename: 'file.txt',
  size: 42,
  uploadedAt: '2026-03-24T00:00:00.000Z',
  expiresAt: '2026-03-25T00:00:00.000Z',
  deleteToken: 'xxxxxxxxxxxxxxxx',
};

describe('GET /api/v1/file/info/', () => {
  it('returns 404 for unknown token', async () => {
    const req = new Request('https://example.com/api/v1/file/info/?token=notexist');
    const res = await handleInfo(req, env);
    expect(res.status).toBe(404);
  });

  it('returns FilesMetadata shape for a known token', async () => {
    await setMetadata(env.KV_METADATA, 'tok00001', SAMPLE);
    const req = new Request('https://example.com/api/v1/file/info/?token=tok00001');
    const res = await handleInfo(req, env);
    expect(res.status).toBe(200);
    const body = await res.json() as Record<string, unknown>;
    expect(body.basePath).toBeNull();
    expect(Array.isArray(body.files)).toBe(true);
    expect((body.files as { path: string }[])[0].path).toBe('file.txt');
    expect(body.totalFileSize).toBe('42');
  });

  it('accepts a full /d/ URL as the token query param', async () => {
    await setMetadata(env.KV_METADATA, 'tok00001', SAMPLE);
    const tokenUrl = encodeURIComponent('https://odin-worker.workers.dev/d/tok00001');
    const req = new Request(`https://example.com/api/v1/file/info/?token=${tokenUrl}`);
    const res = await handleInfo(req, env);
    expect(res.status).toBe(200);
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- info
```

Expected: FAIL.

- [ ] **Step 3: Implement src/handlers/info.ts**

Create `odin-worker/src/handlers/info.ts`:
```typescript
import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { extractTokenCode } from '../lib/token';
import { jsonError } from '../lib/response';

export async function handleInfo(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const rawToken = url.searchParams.get('token') ?? '';
  const token = extractTokenCode(rawToken);

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  return Response.json({
    basePath: null,
    files: [{ path: metadata.filename }],
    totalFileSize: String(metadata.size),
  });
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- info
```

Expected: PASS — all 3 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/handlers/info.ts odin-worker/src/__tests__/info.test.ts
git commit -m "feat: add info handler returning FilesMetadata shape"
```

---

## Task 8: handlers/download.ts

**Files:**
- Create: `odin-worker/src/handlers/download.ts`
- Create: `odin-worker/src/__tests__/download.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/download.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleDownload } from '../handlers/download';
import { setMetadata } from '../lib/kv';

async function seedFile(token: string, filename: string, content: string) {
  await env.R2_BUCKET.put(`${token}/${filename}`, new TextEncoder().encode(content));
  await setMetadata(env.KV_METADATA, token, {
    r2Key: `${token}/${filename}`,
    filename,
    size: content.length,
    uploadedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
    deleteToken: 'xxxxxxxxxxxxxxxx',
  });
}

describe('GET /api/v1/file/download/', () => {
  it('returns 404 for unknown token', async () => {
    const req = new Request('https://example.com/api/v1/file/download/?token=missing');
    const res = await handleDownload(req, env);
    expect(res.status).toBe(404);
  });

  it('returns file bytes with correct headers', async () => {
    await seedFile('dl000001', 'report.txt', 'download me');
    const req = new Request('https://example.com/api/v1/file/download/?token=dl000001');
    const res = await handleDownload(req, env);
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toBe('application/octet-stream');
    expect(res.headers.get('Filename')).toBe('report.txt');
    expect(res.headers.get('Content-Disposition')).toContain('report.txt');
    expect(res.headers.get('Content-Length')).toBe('11');
    const text = await res.text();
    expect(text).toBe('download me');
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- download
```

Expected: FAIL.

- [ ] **Step 3: Implement src/handlers/download.ts**

Create `odin-worker/src/handlers/download.ts`:
```typescript
import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { extractTokenCode } from '../lib/token';
import { jsonError } from '../lib/response';

export async function handleDownload(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const rawToken = url.searchParams.get('token') ?? '';
  const token = extractTokenCode(rawToken);

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  const object = await env.R2_BUCKET.get(metadata.r2Key);
  if (!object) {
    return jsonError(404, 'not found or expired');
  }

  return new Response(object.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${metadata.filename}"`,
      'Filename': metadata.filename,
      'Content-Length': String(metadata.size),
    },
  });
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- download
```

Expected: PASS — all 2 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/handlers/download.ts odin-worker/src/__tests__/download.test.ts
git commit -m "feat: add download handler with Content-Length and Filename headers"
```

---

## Task 9: handlers/redirect.ts — GET /d/:token

**Files:**
- Create: `odin-worker/src/handlers/redirect.ts`
- Create: `odin-worker/src/__tests__/redirect.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/redirect.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleRedirect } from '../handlers/redirect';
import { setMetadata } from '../lib/kv';

describe('GET /d/:token', () => {
  it('returns 404 when token not found', async () => {
    const req = new Request('https://example.com/d/notfound');
    const res = await handleRedirect(req, env);
    expect(res.status).toBe(404);
  });

  it('serves file bytes directly (no redirect)', async () => {
    const content = 'short url file content';
    await env.R2_BUCKET.put('sh000001/hello.txt', new TextEncoder().encode(content));
    await setMetadata(env.KV_METADATA, 'sh000001', {
      r2Key: 'sh000001/hello.txt',
      filename: 'hello.txt',
      size: content.length,
      uploadedAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 86400000).toISOString(),
      deleteToken: 'yyyyyyyyyyyyyyyy',
    });
    const req = new Request('https://example.com/d/sh000001');
    const res = await handleRedirect(req, env);
    expect(res.status).toBe(200);
    // Must match download handler headers exactly (same headers as /api/v1/file/download/)
    expect(res.headers.get('Filename')).toBe('hello.txt');
    expect(res.headers.get('Content-Disposition')).toContain('hello.txt');
    expect(res.headers.get('Content-Length')).toBe(String(content.length));
    expect(await res.text()).toBe(content);
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- redirect
```

Expected: FAIL.

- [ ] **Step 3: Implement src/handlers/redirect.ts**

Create `odin-worker/src/handlers/redirect.ts`:
```typescript
import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { jsonError } from '../lib/response';

export async function handleRedirect(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  // Extract token code: last path segment after /d/
  const segments = url.pathname.split('/').filter(Boolean);
  const dIndex = segments.indexOf('d');
  const token = dIndex !== -1 ? segments[dIndex + 1] : '';

  if (!token) return jsonError(404, 'not found or expired');

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) return jsonError(404, 'not found or expired');

  const object = await env.R2_BUCKET.get(metadata.r2Key);
  if (!object) return jsonError(404, 'not found or expired');

  return new Response(object.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${metadata.filename}"`,
      'Filename': metadata.filename,
      'Content-Length': String(metadata.size),
    },
  });
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- redirect
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/handlers/redirect.ts odin-worker/src/__tests__/redirect.test.ts
git commit -m "feat: add /d/:token browser short-URL handler"
```

---

## Task 10: handlers/delete.ts

**Files:**
- Create: `odin-worker/src/handlers/delete.ts`
- Create: `odin-worker/src/__tests__/delete.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/delete.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleDelete } from '../handlers/delete';
import { setMetadata, setCleanupEntry, getMetadata } from '../lib/kv';

async function seedUpload(token: string) {
  await env.R2_BUCKET.put(`${token}/file.txt`, new TextEncoder().encode('data'));
  await setMetadata(env.KV_METADATA, token, {
    r2Key: `${token}/file.txt`,
    filename: 'file.txt',
    size: 4,
    uploadedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
    deleteToken: 'correctsecret123',
  });
  await setCleanupEntry(env.KV_METADATA, token, {
    token,
    r2Key: `${token}/file.txt`,
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
  });
}

describe('DELETE /delete/:token', () => {
  it('returns 404 when token not found', async () => {
    const req = new Request('https://example.com/delete/missing?secret=abc', { method: 'DELETE' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(404);
  });

  it('returns 403 when secret is wrong', async () => {
    await seedUpload('de000001');
    const req = new Request('https://example.com/delete/de000001?secret=wrongsecret12345', { method: 'DELETE' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(403);
  });

  it('returns 204 and cleans up R2, metadata KV, and cleanup KV on valid delete', async () => {
    await seedUpload('de000002');
    const req = new Request('https://example.com/delete/de000002?secret=correctsecret123', { method: 'DELETE' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(204);

    // KV metadata gone
    expect(await getMetadata(env.KV_METADATA, 'de000002')).toBeNull();

    // R2 object gone
    expect(await env.R2_BUCKET.get('de000002/file.txt')).toBeNull();

    // Cleanup index entry also gone (spec step 6)
    expect(await env.KV_METADATA.get('cleanup:de000002')).toBeNull();
  });

  it('also accepts GET method (browser-friendly)', async () => {
    await seedUpload('de000003');
    const req = new Request('https://example.com/delete/de000003?secret=correctsecret123', { method: 'GET' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(204);
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- delete
```

Expected: FAIL.

- [ ] **Step 3: Implement src/handlers/delete.ts**

Create `odin-worker/src/handlers/delete.ts`:
```typescript
import type { Env } from '../types';
import { getMetadata, deleteMetadata, deleteCleanupEntry } from '../lib/kv';
import { jsonError } from '../lib/response';

export async function handleDelete(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const segments = url.pathname.split('/').filter(Boolean);
  // Path: /delete/:token
  const deleteIndex = segments.indexOf('delete');
  const token = deleteIndex !== -1 ? segments[deleteIndex + 1] : '';

  if (!token) return jsonError(404, 'not found or expired');

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) return jsonError(404, 'not found or expired');

  const secret = url.searchParams.get('secret') ?? '';
  if (secret !== metadata.deleteToken) {
    return jsonError(403, 'invalid delete token');
  }

  await env.R2_BUCKET.delete(metadata.r2Key);
  await deleteMetadata(env.KV_METADATA, token);
  await deleteCleanupEntry(env.KV_METADATA, token);

  return new Response(null, { status: 204 });
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- delete
```

Expected: PASS — all 4 tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/handlers/delete.ts odin-worker/src/__tests__/delete.test.ts
git commit -m "feat: add delete handler supporting GET and DELETE methods"
```

---

## Task 11: cron.ts — hourly R2 cleanup

**Files:**
- Create: `odin-worker/src/cron.ts`
- Create: `odin-worker/src/__tests__/cron.test.ts`

- [ ] **Step 1: Write failing tests**

Create `odin-worker/src/__tests__/cron.test.ts`:
```typescript
import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { runCleanup } from '../cron';
import { setCleanupEntry } from '../lib/kv';

describe('runCleanup', () => {
  it('deletes R2 object and cleanup entry for expired uploads', async () => {
    const token = 'cr000001';
    await env.R2_BUCKET.put(`${token}/file.txt`, new TextEncoder().encode('x'));
    const past = new Date(Date.now() - 1000).toISOString(); // already expired
    await setCleanupEntry(env.KV_METADATA, token, { token, r2Key: `${token}/file.txt`, expiresAt: past });

    await runCleanup(env);

    expect(await env.R2_BUCKET.get(`${token}/file.txt`)).toBeNull();
    expect(await env.KV_METADATA.get(`cleanup:${token}`)).toBeNull();
  });

  it('does NOT delete R2 object for unexpired uploads', async () => {
    const token = 'cr000002';
    await env.R2_BUCKET.put(`${token}/file.txt`, new TextEncoder().encode('y'));
    const future = new Date(Date.now() + 86400000).toISOString();
    await setCleanupEntry(env.KV_METADATA, token, { token, r2Key: `${token}/file.txt`, expiresAt: future });

    await runCleanup(env);

    expect(await env.R2_BUCKET.get(`${token}/file.txt`)).not.toBeNull();
    expect(await env.KV_METADATA.get(`cleanup:${token}`)).not.toBeNull();
  });
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- cron
```

Expected: FAIL.

- [ ] **Step 3: Implement src/cron.ts**

Create `odin-worker/src/cron.ts`:
```typescript
import type { Env } from './types';
import { listCleanupEntries, deleteCleanupEntry } from './lib/kv';

export async function runCleanup(env: Env): Promise<void> {
  const entries = await listCleanupEntries(env.KV_METADATA);
  const now = Date.now();

  for (const entry of entries) {
    const expiresAt = new Date(entry.expiresAt).getTime();
    if (expiresAt < now) {
      // Delete R2 object based on expiresAt in the cleanup index.
      // Do NOT look up metadata KV — it will already be gone.
      await env.R2_BUCKET.delete(entry.r2Key);
      await deleteCleanupEntry(env.KV_METADATA, entry.token);
    }
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test -- cron
```

Expected: PASS — both tests green.

- [ ] **Step 5: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/cron.ts odin-worker/src/__tests__/cron.test.ts
git commit -m "feat: add hourly cron cleanup for expired R2 objects"
```

---

## Task 12: src/index.ts — router

**Files:**
- Create: `odin-worker/src/index.ts`

- [ ] **Step 1: Write the router**

Create `odin-worker/src/index.ts`:
```typescript
import type { Env } from './types';
import { handleUpload } from './handlers/upload';
import { handleInfo } from './handlers/info';
import { handleDownload } from './handlers/download';
import { handleConfig } from './handlers/config';
import { handleRedirect } from './handlers/redirect';
import { handleDelete } from './handlers/delete';
import { runCleanup } from './cron';
import { jsonError } from './lib/response';

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const { method, pathname } = url;

    if (method === 'POST' && pathname === '/api/v1/file/upload/') {
      return handleUpload(req, env);
    }
    if (method === 'GET' && pathname === '/api/v1/file/info/') {
      return handleInfo(req, env);
    }
    if (method === 'GET' && pathname === '/api/v1/file/download/') {
      return handleDownload(req, env);
    }
    if (method === 'GET' && pathname === '/api/v1/config/') {
      return handleConfig(req, env);
    }
    if (method === 'GET' && pathname.startsWith('/d/')) {
      return handleRedirect(req, env);
    }
    if ((method === 'GET' || method === 'DELETE') && pathname.startsWith('/delete/')) {
      return handleDelete(req, env);
    }

    return jsonError(404, 'not found');
  },

  async scheduled(_event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(runCleanup(env));
  },
};
```

- [ ] **Step 2: Run full test suite**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npm test
```

Expected: All tests across all test files pass (green).

- [ ] **Step 3: Type-check**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker && npx tsc --noEmit
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/src/index.ts
git commit -m "feat: add router wiring all handlers and cron job"
```

---

## Task 13: Provision Cloudflare resources and deploy

> **Prerequisites:** You must have a Cloudflare account. Install wrangler globally or use `npx wrangler`. Run `npx wrangler login` to authenticate.

- [ ] **Step 1: Create the R2 bucket**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker
npx wrangler r2 bucket create odin-files
```

Expected: `Created bucket 'odin-files'`

- [ ] **Step 2: Create the KV namespace and get IDs**

```bash
npx wrangler kv namespace create odin-metadata
npx wrangler kv namespace create odin-metadata --preview
```

Both commands print an `id`. Copy them and update `wrangler.toml`:
```toml
[[kv_namespaces]]
binding = "KV_METADATA"
id = "<production-id-from-step-above>"
preview_id = "<preview-id-from-step-above>"
```

- [ ] **Step 3: Set PUBLIC_URL to your actual workers.dev subdomain**

Update `wrangler.toml` `[vars]` section:
```toml
[vars]
PUBLIC_URL = "https://odin-worker.<your-cf-subdomain>.workers.dev"
```

Your workers.dev subdomain is shown in the Cloudflare dashboard under Workers & Pages.

- [ ] **Step 4: Deploy**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin/odin-worker
npx wrangler deploy
```

Expected output includes: `https://odin-worker.<subdomain>.workers.dev`

- [ ] **Step 5: Smoke test the deployed Worker**

```bash
# Config endpoint
curl https://odin-worker.<subdomain>.workers.dev/api/v1/config/

# Upload a file
curl -X POST https://odin-worker.<subdomain>.workers.dev/api/v1/file/upload/ \
  -F "file=@/tmp/test.txt" -F "directoryName=test" -F "totalFileSize=10"
```

Expected: Config returns JSON with `home`, `upload`, `token` keys. Upload returns `{ token, deleteToken }`.

- [ ] **Step 6: Commit wrangler.toml with real IDs**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add odin-worker/wrangler.toml
git commit -m "chore: add real KV namespace IDs to wrangler.toml"
```

---

## Task 14: Update Flutter app .env

**Files:**
- Modify: `.env`

- [ ] **Step 1: Update .env with the deployed Worker URL**

Edit `/home/codenameakshay/Development/codenameakshay/odin/.env` to exactly the following (remove `GITHUB_TOKEN` and `GITHUB_USERNAME` — they are not used by the Cloudflare backend):
```
API_URL=https://odin-worker.<your-subdomain>.workers.dev/
API_VERSION=v1
SUCCESSFUL_STATUS_CODE=200
```

Note the **trailing slash** on `API_URL` — the Flutter `EnvironmentService` and `ONetworkingBox` expect it.

- [ ] **Step 2: Run the Flutter app and do an end-to-end test**

```bash
cd /home/codenameakshay/Development/codenameakshay/odin && fvm flutter run
```

Test manually:
1. Open app → config loads (buttons show correct text)
2. Tap "Send files" → pick a file → upload completes → token URL shown
3. Copy token → tap "Receive files" → paste token → file info shown → download works
4. Use the deleteToken URL in a browser → file deleted → subsequent download returns 404

- [ ] **Step 3: Commit .env update**

> ⚠️ `.env` typically contains secrets. If `GITHUB_TOKEN` or other credentials are in the file, **do not commit it**. Only commit if the file contains no secrets and is already tracked by git.

```bash
cd /home/codenameakshay/Development/codenameakshay/odin
git add .env
git commit -m "chore: point Flutter app to Cloudflare Worker backend"
```
