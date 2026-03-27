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

Reads `.env` (or `--env-file`) using:

- `API_URL` (default `https://getodin.com/`)
- `API_VERSION` (default `v1`)
- `SUCCESSFUL_STATUS_CODE` (default `200`)

Global overrides:

- `--api-url`
- `--api-version`

## Headless behavior

- `upload` prints share token to stdout on success.
- `download` prints output path to stdout on success.
- `--json` prints structured success/failure payloads.
- Non-zero exit code is returned on failure.

## TUI keys

- `↑/↓` or `j/k`: navigate
- `enter`: select/open file or navigate directory
- `d`: continue upload after selecting files
- `s`: upload flow = add current directory, download flow = choose output directory
- `esc`: back/cancel
- `?`: toggle help
- `q` or `ctrl+c`: quit
