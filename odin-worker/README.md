# odin-worker

Cloudflare Workers backend for the Odin file-sharing app.

## Architecture

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Compute | Cloudflare Workers (TypeScript) | HTTP handlers + hourly cron |
| File storage | Cloudflare R2 | Binary file blobs, keyed by `<token>/<filename>` |
| Metadata | Cloudflare KV | Upload metadata (24h TTL) + cleanup entries (48h TTL) |
| Expiry | Cron Trigger (`0 * * * *`) | Hourly physical deletion of expired R2 objects |

## API

All routes are relative to the worker URL (set `PUBLIC_URL` in `wrangler.toml` after deploying).

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/config/` | Static app config consumed by the Flutter client |
| `POST` | `/api/v1/file/upload/` | Upload one or more files (multipart/form-data) |
| `GET` | `/api/v1/file/info/` | Fetch file metadata by token (`?token=<url-or-code>`) |
| `GET` | `/api/v1/file/download/` | Download file bytes by token (`?token=<url-or-code>`) |
| `GET` | `/d/:token` | Direct file download via share URL |
| `GET/DELETE` | `/delete/:token?secret=<s>` | Delete file with secret validation |

### Upload request

`POST /api/v1/file/upload/` accepts `multipart/form-data` with:

| Field | Type | Description |
|-------|------|-------------|
| `file` / `media` | File | One or more file parts (multiple `file` entries are zipped) |
| `totalFileSize` | string | Declared total size in bytes (used for early rejection) |

Max total size: **100 MB**.

### Upload response

```json
{
  "token": "https://<your-worker>.workers.dev/d/aB3kR9mQ",
  "deleteToken": "https://<your-worker>.workers.dev/delete/aB3kR9mQ?secret=XYZ..."
}
```

The `token` field is a full share URL. The Flutter client displays it and the recipient pastes it (or just the 8-char code) into the download field.

## Development

```bash
cd odin-worker

# Copy the example config and fill in your values
cp wrangler.toml.example wrangler.toml
# (wrangler.toml is gitignored — never commit it)

npm install

# Run tests (uses Miniflare via @cloudflare/vitest-pool-workers)
npm test

# Deploy
npx wrangler deploy
```

## Wrangler bindings (`wrangler.toml.example`)

| Binding | Type | Name |
|---------|------|------|
| `R2_BUCKET` | R2 | `odin-files` |
| `KV_METADATA` | KV | `941ae40d709d46d59869d16be3fe00ad` |
| `PUBLIC_URL` | var | `https://odin.prismwalls.workers.dev` |

## Expiry model

Files expire after **24 hours**:

1. KV metadata TTL = 24h (logical expiry — info/download return 404 after this)
2. KV cleanup entry TTL = 48h (safety net)
3. Hourly cron deletes R2 objects for entries past their `expiresAt` timestamp

## Directory structure

```
src/
├── index.ts          # Router + scheduled handler export
├── types.ts          # Env interface
├── cron.ts           # Hourly cleanup logic
├── handlers/
│   ├── config.ts
│   ├── upload.ts
│   ├── info.ts
│   ├── download.ts
│   ├── redirect.ts
│   └── delete.ts
└── lib/
    ├── kv.ts         # KV helpers (metadata + cleanup entries)
    ├── token.ts      # Token generation + URL extraction
    ├── zip.ts        # fflate-based zip for multi-file uploads
    └── response.ts   # jsonError helper
test/
└── *.test.ts         # vitest + @cloudflare/vitest-pool-workers
```
