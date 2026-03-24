# Cloudflare Backend Design — Odin File Sharing

**Date:** 2026-03-24
**Status:** Approved
**Scope:** Replace the existing `getodin.com` backend with a self-hosted Cloudflare Workers backend. No external service dependencies.

---

## Overview

Build a Cloudflare Workers backend that handles all file upload, download, metadata, and configuration endpoints currently consumed by the Odin Flutter app. Files are stored for 24 hours and then permanently deleted. URL shortening is built-in — the shareable token is a full URL pointing to the Worker itself. Each upload also returns a per-upload delete URL.

---

## Constraints

- **Max file size:** 100 MB per upload (phase 1). Multipart R2 uploads (up to 5 TB) are a planned future phase.
- **Platform:** Cloudflare Workers + R2 + KV. No external APIs, no third-party services.
- **Subdomain:** `*.workers.dev` for now; custom domain migration deferred.
- **Flutter app changes:** Minimal — only `.env` URL update required. API contract is preserved exactly.
- **Rate limiting:** Out of scope for phase 1. To be added in a future hardening pass.

---

## Infrastructure

| Component | Cloudflare Service | Purpose |
|-----------|-------------------|---------|
| API Worker | Cloudflare Workers | Handles all HTTP endpoints and request routing |
| File storage | Cloudflare R2 | Stores raw file bytes, keyed by token |
| Metadata store | Cloudflare KV | Stores per-upload metadata with 24h native TTL |
| Cleanup index | Cloudflare KV | One key per upload (`cleanup:<token>`), tracks R2 keys pending deletion |
| Scheduled cleanup | Cron Trigger (Workers) | Runs hourly, deletes expired R2 objects |

**Wrangler bindings:**
- `R2_BUCKET` → R2 bucket `odin-files`
- `KV_METADATA` → KV namespace for upload metadata and cleanup index

**Worker environment variable:**
- `PUBLIC_URL` — the Worker's own public base URL (e.g., `https://odin.workers.dev`), set in `wrangler.toml`. Used to construct token and deleteToken URLs in upload responses.

---

## KV Metadata Schema

**Metadata entry:**
Key: `<8-char-token>` (e.g., `aB3kR9mQ`)
TTL: 86400 seconds (24 hours)

```json
{
  "r2Key": "aB3kR9mQ/filename.zip",
  "filename": "filename.zip",
  "size": 4820234,
  "uploadedAt": "2026-03-24T10:00:00Z",
  "expiresAt": "2026-03-25T10:00:00Z",
  "deleteToken": "x9Kp2mNqLzRt4vWy"
}
```

**Cleanup index entries (one key per upload — avoids concurrent-write corruption):**
Key: `cleanup:<token>` (e.g., `cleanup:aB3kR9mQ`)
TTL: 172800 seconds (48 hours, safety net)

```json
{
  "token": "aB3kR9mQ",
  "r2Key": "aB3kR9mQ/filename.zip",
  "expiresAt": "2026-03-25T10:00:00Z"
}
```

Using one KV key per upload (rather than a single shared array key) avoids last-write-wins corruption under concurrent uploads.

---

## Token Generation

- 8-char alphanumeric token drawn from `[A-Za-z0-9]` (62^8 ≈ 218 trillion combinations).
- Generated using `crypto.getRandomValues` (available in Workers runtime).
- The Worker checks KV for collision before use; retries up to 3 times on collision (negligible probability at expected scale).
- Delete token: 16-char alphanumeric string, same generation method.

---

## API Endpoints

All endpoints live on the Worker at `https://<name>.workers.dev`.

**Token extraction rule (used by `/info`, `/download`, `/d/:token`):**
When a token value is a full URL (e.g., `https://odin.workers.dev/d/aB3kR9mQ`), extract the 8-char code as the last path segment after `/d/`. When a token value is already an 8-char code, use it directly.

---

### `POST /api/v1/file/upload/`

Accepts `multipart/form-data`. The Flutter app sends two possible field names for the file:
- `file` — used by the multi-file path (`uploadFilesAnonymous`)
- `media` — used by the single-file path (`uploadFileAnonymous`)

The Worker accepts **both** `file` and `media` field names. Additional fields: `directoryName` (ignored), `totalFileSize` (used for validation).

**Processing:**
1. Validate total size ≤ 100 MB; return `413` if exceeded.
2. Collect all file fields (from `file` and/or `media` entries).
3. If more than one file, zip them in-Worker using `fflate`.
4. Generate a cryptographically random 8-char token; check KV for collision, retry up to 3 times.
5. Store file bytes in R2 at key `<token>/<filename>`.
6. Generate a 16-char `deleteToken`.
7. Write metadata KV entry with 24h TTL.
8. Write cleanup index KV entry (`cleanup:<token>`) with 48h TTL.

**Response `200`:**
```json
{
  "token": "https://<worker>.workers.dev/d/aB3kR9mQ",
  "deleteToken": "https://<worker>.workers.dev/delete/aB3kR9mQ?secret=x9Kp2mNqLzRt4vWy"
}
```

---

### `GET /api/v1/file/info/?token=<token>`

Extracts 8-char code using the token extraction rule, looks up KV.

**Response `200`** (matches `FilesMetadata` model exactly — all fields are nullable strings):
```json
{
  "basePath": null,
  "files": [{ "path": "filename.zip" }],
  "totalFileSize": "4820234"
}
```

Note: `totalFileSize` is a **string**, not an integer. `basePath` is always `null` (not used by this backend).

**Response `404`:** Token not found or expired.

---

### `GET /api/v1/file/download/?token=<token>`

Extracts 8-char code, looks up KV, fetches bytes from R2, streams response.

**Response headers:**
- `Content-Disposition: attachment; filename=<filename>`
- `Filename: <filename>` (read by the Flutter Dio client)
- `Content-Type: application/octet-stream`
- `Content-Length: <size-in-bytes>` (required for Dio progress callbacks to reach 100%)

---

### `GET /api/v1/config/`

Returns static configuration JSON. All fields are required non-null strings (the Flutter deserialiser casts directly without null checks). Field names must match exactly.

**Response `200`:**
```json
{
  "home": {
    "title": "Odin",
    "primaryButtonText": "Send files",
    "secondaryButtonText": "Receive files"
  },
  "upload": {
    "title": "Uploading",
    "description": "Your files are being uploaded",
    "backButtonText": "Back",
    "cancelDefaultText": "Cancel",
    "errorButtonText": "Retry",
    "errorDefaultText": "Upload failed",
    "successDefaultText": "Upload complete"
  },
  "token": {
    "title": "Receive files",
    "description": "Enter the token to download your files",
    "textFieldHintText": "Enter token",
    "backButtonText": "Back",
    "primaryButtonText": "Download"
  }
}
```

---

### `GET /d/:token`

Browser-friendly short URL. Extracts 8-char code and returns the file directly (same logic as `/api/v1/file/download/`) — does NOT redirect, to avoid the download endpoint needing to re-parse the redirect URL. Returns the same headers as the download endpoint.

---

### `GET /delete/:token?secret=<deleteToken>` and `DELETE /delete/:token?secret=<deleteToken>`

Both `GET` and `DELETE` methods are accepted on this route. `GET` is supported so the delete URL is usable directly in a browser. Steps:

1. Look up KV entry for token.
2. If not found, return `404`.
3. If `secret` query param does not match stored `deleteToken`, return `403`.
4. Delete R2 object at `r2Key`.
5. Delete metadata KV entry.
6. Delete cleanup index KV entry (`cleanup:<token>`).

**Response `204`:** No content on success.

---

## Expiry Strategy (Two-Layer)

**Layer 1 — KV TTL (immediate logical expiry):**
KV entries are written with a 24h TTL. Once expired, all read endpoints (`/info`, `/download`, `/d/:token`) receive `null` from KV and return `404`. The file is unreachable even if the R2 object still exists physically.

**Layer 2 — Cron cleanup (physical R2 deletion):**
A scheduled Worker (`cron = "0 * * * *"`) runs hourly. It lists all KV keys with prefix `cleanup:` and for each entry:

1. Read the entry's `expiresAt` field from the stored JSON value.
2. If `expiresAt < now()`, delete the R2 object at `r2Key`.
3. Delete the `cleanup:<token>` KV key.

**Important:** The cron relies entirely on `expiresAt` stored in the cleanup index entry — it does NOT look up the metadata KV entry (which will already be gone). This ensures orphaned R2 objects are cleaned up even after metadata KV expiry.

---

## Error Handling

All error responses return JSON bodies so the Flutter app's existing failure handling works unchanged.

| Scenario | Status | Body |
|----------|--------|------|
| Token not found or expired | 404 | `{ "error": "not found or expired" }` |
| File exceeds 100 MB | 413 | `{ "error": "file too large" }` |
| No file field in request | 400 | `{ "error": "no file provided" }` |
| Wrong delete secret | 403 | `{ "error": "invalid delete token" }` |
| R2 or KV internal failure | 500 | `{ "error": "storage error" }` |

---

## Worker Project Structure

```
odin-worker/
├── src/
│   ├── index.ts              # Router — dispatches requests to handlers
│   ├── handlers/
│   │   ├── upload.ts         # POST /api/v1/file/upload/
│   │   ├── info.ts           # GET /api/v1/file/info/
│   │   ├── download.ts       # GET /api/v1/file/download/
│   │   ├── config.ts         # GET /api/v1/config/
│   │   ├── redirect.ts       # GET /d/:token (serves file directly)
│   │   └── delete.ts         # GET+DELETE /delete/:token
│   ├── lib/
│   │   ├── token.ts          # Random token + deleteToken generation, collision check
│   │   ├── zip.ts            # Multi-file zip using fflate
│   │   └── kv.ts             # KV read/write helpers, cleanup index management
│   └── cron.ts               # Scheduled cleanup job
├── wrangler.toml             # CF config: bindings, cron trigger, routes, PUBLIC_URL
├── package.json
└── tsconfig.json
```

**Runtime dependencies:**
- `fflate` — fast, WASM-free zip library that works in the Workers runtime
- No other runtime dependencies; all storage via native R2/KV bindings

---

## Flutter App Changes

Only `.env` requires updating:

```
API_URL=https://<your-worker-name>.workers.dev/
API_VERSION=v1
SUCCESSFUL_STATUS_CODE=200
```

**Optional model update:**
`UploadFilesSuccess` in `lib/network/responses.dart` gains an optional `deleteToken` field so the delete URL can be stored or displayed in the success UI. Not required for core functionality — the field is ignored if absent from the model.

---

## Future Phases

- **Phase 2:** R2 multipart upload for files up to 500 MB — Worker orchestrates multipart upload to R2.
- **Phase 3:** Presigned R2 URLs for files up to several GB — client uploads directly to R2, Worker only handles metadata.
- **Rate limiting:** Per-IP KV counter with configurable request-per-minute threshold.
- **Custom domain:** Swap `workers.dev` for a custom domain via wrangler route config; no code changes needed.
