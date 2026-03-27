# odin_core

Pure Dart core client for Odin upload/download APIs.

## What it provides

- API client + repository for:
  - anonymous upload
  - metadata fetch
  - download
- Shared token parser/builder for:
  - plain file code (`abc123`)
  - full URL (`https://.../d/abc123`)
  - encrypted share URL with fragment key (`#k=...&v=1`)
- Upload preparation pipeline:
  - files-only uploads
  - directory + multi-file zip preparation
- Client-side encryption/decryption container logic used by app + CLI
- Typed result/failure models for consistent error handling

## Encryption behavior

- Upload encryption is enabled by default in repository requests.
- Decryption key is embedded in share token fragment (`#k=...`) and is never sent to backend query params.
- Download path auto-detects encrypted payloads and decrypts when key is present.
- Legacy plaintext downloads remain supported.
