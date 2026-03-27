# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This App Does

**Odin** is an open-source, cross-platform file sharing application. Users can:
- Upload files (encrypted with AES-256) and receive a shareable 8-character token
- Download files using the token — no account required
- Share files anonymously; uploaded files are auto-deleted after 15 hours
- Handle multi-file uploads (auto-zipped before upload)

The backend uses GitHub repositories as storage.

---

## Flutter / Dart CLI Rule

ALWAYS use `fvm flutter` instead of bare `flutter`.
ALWAYS use `fvm dart` instead of bare `dart`.
Flutter version is pinned to **stable** via `.fvmrc`.

---

## Mono-repo Structure

```
odin/                    # Flutter app (main package)
packages/
├── odin_core/           # Shared Dart library (used by app + CLI)
│   └── lib/src/         # share_token, upload_preparation, crypto_container,
│                        # odin_repository, models, requests, responses, result
└── odin_cli/            # CLI tool (bin/odin.dart)
```

`odin_core` is a local path dependency in `pubspec.yaml`. It holds the `Result<S,F>` type, `ParsedShareToken`, `prepareUploadInputs`, and the abstract `OdinRepository` contract shared between the Flutter app and the CLI.

---

## Architecture Overview

```
lib/
├── amenities/     # Device/system capability abstraction (connectivity, auth, device info)
├── booters/       # App initialization sequence (BooterService, AmenitiesBooter, ConfigBooter)
├── constants/     # Colors (OColor), theme, sizes, image paths
├── model/         # App-local DTOs (JSON-serializable, generated via json_serializable)
├── network/       # Repository pattern + Dio networking (OdinRepository → OdinRepositoryImpl)
├── pages/         # UI screens: Home, Upload, Download (each has widgets/ subfolder)
├── painters/      # Custom Flutter painters
├── providers/     # ChangeNotifier providers: DioNotifier, BooterNotifier, FileNotifier, PendingUploadsNotifier
├── router/        # Auto-route configuration (code-generated router.gr.dart)
├── services/      # Business logic services
├── utilities/     # Helpers and extensions
├── widgets/       # Shared reusable UI components
└── main.dart      # Entry point
```

---

## Key Flows

### Upload Flow
1. User picks files via `FileService.pickMultipleFiles()`
2. `prepareUploadInputs()` (from `odin_core`) zips if multiple files or directories
3. `EncryptionService.encryptFile()` with random 16-char AES-256 password
4. `DioNotifier.uploadFilesAnonymous()` POSTs the encrypted file
5. Server returns an 8-character alphanumeric file code (the shareable token)

### Download Flow
1. User pastes the 8-character token into DownloadPage
2. `parseShareToken()` (from `odin_core`) validates and extracts the `fileCode`
3. `DioNotifier.downloadFile()` downloads the encrypted file using the code
4. `EncryptionService.decryptFile()` decrypts; `ZipService.unzipFile()` if multi-file

### Boot Sequence
1. `main()` → `setupLocator()` (GetIt DI)
2. `EnvironmentService.init()` loads `.env`
3. `BooterNotifier` triggers `BooterService.bootUp()`
4. `AmenitiesBooter` → `CoreAmenity` initialization
5. `ConfigBooter` → fetches remote `Config` from API
6. App renders when `AppBootStatus.booted`

---

## State Management

- **Provider + ChangeNotifier** for widget-level state
- **RxDart `BehaviorSubject`** for reactive streams (`DioService` exposes `apiStatusStream` as `ValueStream`)
- **DioNotifier** — central provider managing upload/download progress, cancellation tokens, and success/failure states; also holds two status streams (`apiStatus` + `miniApiStatus`)
- **BooterNotifier** — app initialization lifecycle state
- No `setState` in pages; all rebuild logic via `context.watch<DioNotifier>()`

---

## Dependency Injection

All services registered with **GetIt** in `lib/services/locator.dart`:
- Singletons: `AppRouter`, `DioNotifier`, `BooterNotifier`, `OColor`, `OTheme`
- Lazy singletons: `EnvironmentService`, `DioService`, `EncryptionService`, `ZipService`, `FileService`, `RandomService`, `ShortenerService`, `ToastService`, `PreferencesService`, `PendingUploadsNotifier`, `OdinService`

Access via `locator<ServiceName>()`.

---

## Networking

- **Dio** HTTP client configured in `ONetworkingBox`
- Base URL from `EnvironmentService` (API_URL + API_VERSION from `.env`)
- Interceptors: logging, retry, no-token (anonymous)
- Repository pattern: abstract `OdinRepository` (in `odin_core`), implemented by `OdinRepositoryImpl` in `lib/network/repository_impl.dart`
- All results typed as `Result<Success, Failure>` — no raw exceptions thrown to UI

**API Endpoints:**
```
POST /api/v1/file/upload/      Upload files
GET  /api/v1/file/info/        Fetch file metadata
GET  /api/v1/file/download/    Download file
GET  /api/v1/config/           Fetch app configuration
```

---

## Navigation

- **auto_route** with code generation (`router.gr.dart`)
- Three routes: `/` (HomePage), `/upload` (UploadPage), `/download` (DownloadPage)
- UploadPage receives `List<XFile>` as route parameter
- Custom `AppRouteObserver` for navigation logging

Run after changing routes:
```bash
make codegen
```

---

## Environment Configuration

`.env` file (must exist at project root for app to run):
```
API_URL=https://getodin.com/
API_VERSION=v1
SUCCESSFUL_STATUS_CODE=200
GITHUB_TOKEN=
GITHUB_USERNAME=
```

Loaded via `flutter_dotenv` into `EnvironmentService` → `Environment` model.

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅     | APK builds |
| iOS      | ✅     | |
| macOS    | ✅     | Window size: 720×512 min |
| Windows  | ✅     | Window size: 720×512 min |
| Linux    | ✅     | Needs cmake, ninja-build, GTK |
| Web      | ✅     | Splash disabled for web |

Desktop window setup uses `bitsdojo_window` (only initialised on non-web desktop targets).

---

## Common Commands

All commands must be run from the project root.

```bash
make get                    # fvm flutter pub get
make run                    # fvm flutter run (DEVICE=linux or ARGS='-d chrome' optional)
make analyze                # fvm flutter analyze --no-fatal-infos
make analyze-strict         # analyze with infos fatal
make test                   # fvm flutter test
make format                 # fvm dart format lib test
make format-check           # fail if code is not formatted
make fix                    # dart fix --apply
make check                  # CI pipeline: format-check + analyze + test
make codegen                # build_runner (auto_route + JSON serialization)
make codegen-watch          # build_runner in watch mode
make clean                  # flutter clean

make build-apk-debug
make build-apk-release      # fat APK, all ABIs
make build-apk-split-release  # split per ABI (smaller downloads)
make build-aab-release      # App Bundle for Google Play
make build-linux-debug
make build-linux-release
make build-macos
make build-windows

make icons                  # Regenerate launcher icons
make splash                 # Regenerate splash screens

# CLI package commands
make cli-get                # pub get for odin_core + odin_cli
make cli-analyze            # analyze odin_core + odin_cli
make cli-test               # run odin_core tests
make cli-run ARGS='upload ./file.txt'
make cli-compile            # compile CLI executable to packages/odin_cli/build/odin
```

---

## Code Generation

Must run `make codegen` when changing:
- Route definitions → regenerates `router.gr.dart`
- Models with `@JsonSerializable` → regenerates `*.g.dart` files

---

## Key Models

| Model | Location | Purpose |
|-------|----------|---------|
| `Environment` | `lib/model/` | Loaded from `.env`; holds API_URL, API_VERSION, etc. |
| `Config` | `lib/model/` | Remote app config (UI text for Home/Upload/Download pages) |
| `FileMetadata` / `FilesMetadata` | `odin_core` + `lib/model/` | File info from server |
| `EncryptedFile` | `lib/model/` | Wrapper: encrypted file + AES password |
| `ParsedShareToken` | `odin_core` | Validated 8-char alphanumeric file code |
| `PreparedUpload` | `odin_core` | Result of `prepareUploadInputs()` — files ready to encrypt+upload |
| `Result<S,F>` | `odin_core` | Typed success/failure union; no raw exceptions to UI |

---

## Services Reference

| Service | Responsibility |
|---------|----------------|
| `EnvironmentService` | Load `.env` config |
| `DioService` | Configured Dio HTTP client + `apiStatus`/`miniApiStatus` streams |
| `EncryptionService` | AES-256 encrypt/decrypt |
| `ZipService` | Zip/unzip with `archive` |
| `FileService` | File picker wrapper |
| `ShortenerService` | URL shortening |
| `RandomService` | Random string generation |
| `PreferencesService` | `SharedPreferences` wrapper |
| `ToastService` | Platform-appropriate toasts |
| `BooterService` | Boot sequence orchestration |

---

## Theme

- **Forced dark mode** (`ThemeMode.dark`)
- `flex_color_scheme` for Material 3 theming
- Custom `OColor` class for light/dark color tokens
- Typography: **Inter** (Google Fonts)

---

## Encryption Details

- Algorithm: **AES-256** via `aes_crypt_null_safe`
- Password: 16-character random alphanumeric string
- Token shared with recipient: 8-character file code returned by server (password is NOT embedded in the token)
- Decryption happens entirely client-side

---

## Testing

```bash
make test              # Flutter app tests (test/)
make cli-test          # odin_core tests (packages/odin_core/test/)
make check             # format-check + analyze + test (CI-equivalent)
```

---

## Git & PR Workflow

```bash
git checkout -b feat/<description>   # or fix/<description>
git add <specific files>             # never git add -A or .
git commit -m "type: description"
git push origin HEAD
gh pr create --title "type: description" --body "..."
```

Never force push to main/master.
