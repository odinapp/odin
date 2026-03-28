# odin_cli

Terminal client for Odin uploads/downloads.

## Highlights

- Uses `odin_core` for API + token behavior parity with app
- Full-screen TUI (`dart_tui`) for interactive upload/download flows
- Headless mode for CI, scripts, and non-interactive terminals
- End-to-end encryption enabled by default on upload
- Accepts both raw codes and full share links for download
- Supports legacy plaintext and encrypted payload downloads

## Setup

```bash
cd packages/odin_cli
fvm dart pub get
```

## Usage

```bash
# TUI mode (if terminal is interactive)
fvm dart run bin/odin.dart

# Headless upload (files and/or directories)
fvm dart run bin/odin.dart upload ./file1.txt ./file2.txt
fvm dart run bin/odin.dart upload ./my-folder ./another-file.txt

# Disable encryption for upload (not recommended)
fvm dart run bin/odin.dart upload ./file.txt --no-encrypt

# Headless download
fvm dart run bin/odin.dart download <token> -o ./downloads

# Require encrypted payload when downloading
fvm dart run bin/odin.dart download <token-or-share-url> -o ./downloads --require-encrypted

# JSON output for scripts
fvm dart run bin/odin.dart --json upload ./file.txt
```

Upload defaults:

- Multiple files or any selected directory are zipped before upload.
- Result token is a share link with URL fragment key (`#k=...&v=1`) when encryption is enabled.
- URL fragment is local-only and is not sent in HTTP requests.

## Environment

**Required:** `API_URL` and `API_VERSION` must be set in the process environment (your shell), unless you pass both `--api-url` and `--api-version`, or supply them via an optional `.env` file.

```bash
export API_URL=https://getodin.com/
export API_VERSION=v1
# optional:
export SUCCESSFUL_STATUS_CODE=200
```

Merge order when using `--env-file /path/to/.env`: values from the file are applied first, then **shell variables override** the file. `--api-url` / `--api-version` override both.

If something required is still missing, the CLI exits with a short message listing which variables are unset (exit code `78`).

## Headless behavior

- `upload` prints share token to stdout on success.
- `download` prints output path to stdout on success.
- `--json` prints structured success/failure payloads.
- Non-zero exit code is returned on failure.

## TUI pending uploads

Successful **TUI** uploads are appended to `~/.odin/pending_uploads.json` (same JSON shape as the Flutter app’s pending list, but a separate file). The main menu includes **Pending uploads** when the list is non-empty; open it to scroll all non-expired entries (newest first). On that screen, **`c`** copies the highlighted share token (OSC 52) and **`d`** deletes that upload on the server (GET to the stored delete URL) and removes it from the JSON file. Entries expire after **24 hours** (aligned with `SharingPolicy.fileLifetimeHours` in the mobile app). `--no-color` uses a solid mauve fill for progress instead of a gradient.

## TUI keys

- `↑/↓` or `j/k`: navigate (including the pending-uploads list)
- `enter`: select/open file or navigate directory; on the main menu, choose Upload, Download, Pending uploads, or Quit
- `d`: on the pending-uploads list, delete the highlighted upload on the server; during upload file pick, continue upload after selecting files
- `c`: clear selected upload paths on the upload pick screen; after a successful upload, copy the token to the clipboard; on the pending-uploads list, copy the highlighted token
- `→` (right arrow) at the **end** of the download token field: read the clipboard and insert a normalized token (raw code, share URL, or first line of paste)
- `s`: upload flow = add current directory, download flow = choose output directory
- `esc`: back/cancel
- `?`: toggle help
- `q` or `ctrl+c`: quit
