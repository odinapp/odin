# odin_cli

Terminal client for Odin uploads/downloads.

## Setup

```bash
cd packages/odin_cli
fvm dart pub get
```

## Usage

```bash
# TUI mode (if terminal is interactive)
fvm dart run bin/odin.dart

# Headless upload
fvm dart run bin/odin.dart upload ./file1.txt ./file2.txt

# Headless download
fvm dart run bin/odin.dart download <token> -o ./downloads

# JSON output for scripts
fvm dart run bin/odin.dart --json upload ./file.txt
```

## Environment

Reads `.env` (or `--env-file`) using:

- `API_URL` (default `https://getodin.com/`)
- `API_VERSION` (default `v1`)
- `SUCCESSFUL_STATUS_CODE` (default `200`)

Global overrides:

- `--api-url`
- `--api-version`

## TUI keys

- `↑/↓` or `j/k`: navigate
- `enter`: select/open
- `d`: continue upload after selecting files
- `s`: choose current directory for download target
- `esc`: back/cancel
- `?`: toggle help
- `q` or `ctrl+c`: quit
