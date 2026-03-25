# Odin - Development Guide

## Overview

Odin is a cross-platform file sharing app built with Flutter/Dart. It uses AES-256 encryption, stores files via the GitHub API, and generates short URLs for sharing.

## Cursor Cloud specific instructions

### Flutter SDK

- This project requires **Flutter 2.10.5** (Dart 2.16.2), installed at `/opt/flutter/bin`. Ensure `PATH` includes `/opt/flutter/bin`.
- The Dart SDK constraint is `>=2.12.0 <3.0.0` — do **not** upgrade to Flutter 3.x.

### Running the app

- **Linux desktop**: `flutter run -d linux` (Linux platform support was added via `flutter create --platforms=linux .`; the `linux/` directory is not in the original repo).
- **Web**: `flutter run -d chrome`
- The app requires a `.env` file at the repo root with `GITHUB_TOKEN`, `GITHUB_USERNAME`, and `GITHUB_REPO_NAME`. Without real credentials, the app launches but file upload/download operations will fail.

### Lint / Analyze

- `flutter analyze` — only info-level warnings are expected (deprecated `launch` usage, a few unused fields). No errors.

### Tests

- `flutter test test/random_service_test.dart` — passes cleanly.
- `flutter test test/shortner_service_test.dart` — fails due to missing service locator setup (pre-existing issue).
- `flutter test test/zip_service_test.dart` — fails due to `getExternalStoragePath()` not being implemented on Linux desktop (pre-existing issue; the test was written for Windows).

### Key gotchas

- The `pubspec.lock` pins `logger` at 1.1.0. Running `flutter pub get` without the lockfile resolves logger 1.4.0+, which breaks `lib/services/logger.dart` (the `getTime()` API changed). Always preserve the lockfile.
- The `platform` package must be at 3.1.0+ for compatibility with Dart 2.16.2 (`Platform.packageRoot` was removed). If restoring the original lockfile, run `dart pub upgrade platform` afterward.
- The logger's `LogOutputPrinter` constructor calls `getExternalStorageDirectory()`, which is unimplemented on Linux. This produces a runtime error on startup but does not crash the app.
- Build requires `libstdc++-14-dev` (or whichever GCC version `clang++` selects) for C++ header resolution.

### Standard commands (see README.md)

- `flutter pub get` — install dependencies
- `flutter run` — run the app
- `flutter build linux` — build release binary
