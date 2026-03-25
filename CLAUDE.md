# Odin — Flutter File Sharing App

## What This App Does

**Odin** is an open-source, cross-platform file sharing application. Users can:
- Upload files (encrypted with AES-256) and receive a shareable token/link
- Download files using the token — no account required
- Share files anonymously; uploaded files are auto-deleted after 15 hours
- Handle multi-file uploads (auto-zipped before encryption)

The backend uses GitHub repositories as storage. The token encodes a shortened URL to the file plus the decryption password.

---

## Flutter / Dart CLI Rule

ALWAYS use `fvm flutter` instead of bare `flutter`.
ALWAYS use `fvm dart` instead of bare `dart`.
Flutter version is pinned to **stable** via `.fvmrc`.

---

## Architecture Overview

```
lib/
├── amenities/     # Device/system capability abstraction (connectivity, auth, device info)
├── booters/       # App initialization sequence (BooterService, AmenitiesBooter, ConfigBooter)
├── constants/     # Colors (OColor), theme, sizes, image paths
├── model/         # Data models & DTOs (JSON-serializable, generated via json_serializable)
├── network/       # Repository pattern + Dio networking
├── pages/         # UI screens: Home, Upload, Download (each has widgets/ subfolder)
├── painters/      # Custom Flutter painters
├── providers/     # State management (ChangeNotifier): DioNotifier, BooterNotifier
├── router/        # Auto-route configuration (code-generated)
├── services/      # Business logic services
├── utilities/     # Helpers and extensions
├── widgets/       # Shared reusable UI components
└── main.dart      # Entry point
```

---

## Key Flows

### Upload Flow
1. User picks files via `FileService.pickMultipleFiles()`
2. Multiple files → `ZipService.zipFile()`
3. Zip → `EncryptionService.encryptFile()` with random 16-char AES-256 password
4. `DioNotifier.uploadFilesAnonymous()` POSTs the encrypted file
5. Response short URL + password = shareable token shown to user

### Download Flow
1. User pastes token into DownloadPage
2. Last 16 chars = decryption password; remainder = file code
3. `ShortenerService.getShortUrlFromFileCode()` resolves the URL
4. `DioNotifier.downloadFile()` downloads the encrypted file
5. `EncryptionService.decryptFile()` decrypts; `ZipService.unzipFile()` if multi-file

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
- **RxDart `BehaviorSubject`** for reactive streams (API status exposed as `ValueStream`)
- **DioNotifier** — central provider managing upload/download progress, cancellation tokens, and success/failure states
- **BooterNotifier** — app initialization lifecycle state
- No `setState` in pages; all rebuild logic via `context.watch<DioNotifier>()`

---

## Dependency Injection

All services registered with **GetIt** in `lib/services/locator.dart`:
- Singletons: `DioService`, `EncryptionService`, `ZipService`, `FileService`, `RandomService`, `ShortenerService`, `ToastService`, `Logger`
- Lazy singletons: `EnvironmentService`, `PreferencesService`
- Registered before `runApp()`

Access via `locator<ServiceName>()`.

---

## Networking

- **Dio** HTTP client configured in `ONetworkingBox`
- Base URL from `EnvironmentService` (API_URL + API_VERSION from `.env`)
- Interceptors: logging, retry, no-token (anonymous)
- Repository pattern: abstract `OdinRepository`, implemented by `OdinRepositoryImpl`
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

- **auto_route** with code generation (`router.g.dart`)
- Three routes: `/` (HomePage), `/upload` (UploadPage), `/download` (DownloadPage)
- UploadPage receives `List<XFile>` as route parameter
- Custom `AppRouteObserver` for navigation logging

Run after changing routes:
```bash
cd /home/codenameakshay/Development/codenameakshay/odin && fvm dart run build_runner build --delete-conflicting-outputs
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

```bash
# All commands must be run from project root
cd /home/codenameakshay/Development/codenameakshay/odin

make get            # fvm flutter pub get
make run            # fvm flutter run
make analyze        # fvm flutter analyze --no-fatal-infos
make test           # fvm flutter test
make format         # fvm dart format lib test
make codegen        # build_runner (auto_route + JSON serialization)
make build-apk-debug
make build-apk-release
make build-linux-debug
make build-macos
make build-windows
make icons          # Regenerate launcher icons
make splash         # Regenerate splash screens
```

---

## Code Generation

Two generators are used — must run `make codegen` (or build_runner) when changing:
- Route definitions → regenerates `router.g.dart`
- Models with `@JsonSerializable` → regenerates `*.g.dart` files

---

## Key Models

| Model | Purpose |
|-------|---------|
| `Environment` | Loaded from `.env`; holds API_URL, API_VERSION, etc. |
| `Config` | Remote app config (UI text for Home/Upload/Download pages) |
| `FileMetadata` / `FilesMetadata` | File info from server (paths, total size) |
| `EncryptedFile` | Wrapper: encrypted file + AES password |
| `CreateFile` | GitHub API payload for file creation |
| `UploadFilesSuccess/Failure` | Typed result for multi-file upload |
| `FetchFilesMetadataSuccess/Failure` | Typed result for file info |
| `DownloadFileSuccess/Failure` | Typed result for file download |

---

## Services Reference

| Service | File | Responsibility |
|---------|------|----------------|
| `EnvironmentService` | `services/environment_service.dart` | Load `.env` config |
| `DioService` | `services/dio_service.dart` | Configured Dio HTTP client |
| `EncryptionService` | `services/encryption_service.dart` | AES-256 encrypt/decrypt |
| `ZipService` | `services/zip_service.dart` | Zip/unzip with `archive` |
| `FileService` | `services/file_service.dart` | File picker wrapper |
| `ShortenerService` | `services/shortener_service.dart` | Shorten URLs via shrtco.de |
| `RandomService` | `services/random_service.dart` | Random string generation |
| `PreferencesService` | `services/preferences_service.dart` | `SharedPreferences` wrapper |
| `ToastService` | `services/toast_service.dart` | Platform-appropriate toasts |
| `BooterService` | `services/booter_service.dart` | Boot sequence orchestration |
| `Logger` | (via `logger` package) | Structured logging to temp dir |

---

## Theme

- **Forced dark mode** (`ThemeMode.dark`)
- `flex_color_scheme` for Material 3 theming
- Custom `OColor` class for light/dark color tokens
- Typography: **Inter** (Google Fonts)
- Gradient backgrounds on main screens

---

## Encryption Details

- Algorithm: **AES-256** via `aes_crypt_null_safe`
- Password: 16-character random string (alphanumeric)
- Encrypted file uploaded to backend
- Token = shortened_url + raw_password (last 16 chars)
- Decryption happens entirely client-side

---

## Testing

```bash
make test
# or
cd /home/codenameakshay/Development/codenameakshay/odin && fvm flutter test
```

Tests live in `test/`. Run analyze before creating PRs:
```bash
make analyze && make test
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
