# Odin — use FVM-pinned Flutter/Dart (run `fvm install` first).
FLUTTER := fvm flutter
DART    := fvm dart

# Optional: `make run DEVICE=linux` or `make run ARGS='-d chrome'`
DEVICE ?=
ARGS   ?=

.PHONY: help
.DEFAULT_GOAL := help

help: ## Show this help
	@echo "Odin (FVM) — common targets"
	@echo ""
	@grep -hE '^[a-zA-Z0-9_.-]+:.*?##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# --- Dependencies ---

get: ## Resolve packages (`fvm flutter pub get`)
	$(FLUTTER) pub get

deps: get ## Alias for `get`

upgrade: ## Upgrade dependencies (`fvm flutter pub upgrade`)
	$(FLUTTER) pub upgrade

outdated: ## List outdated packages
	$(DART) pub outdated

# --- Run ---

run: get ## Run the app (`DEVICE=linux` or `ARGS='-d macos'` to override)
	@if [ -n "$(DEVICE)" ]; then $(FLUTTER) run -d $(DEVICE) $(ARGS); else $(FLUTTER) run $(ARGS); fi

doctor: ## Flutter doctor (SDK from FVM)
	$(FLUTTER) doctor -v

# --- Quality ---

format: ## Format Dart code (`lib/`, `test/`)
	$(DART) format lib test

fmt: format ## Alias for `format`

format-check: ## Fail if Dart code is not formatted
	$(DART) format --output=none --set-exit-if-changed lib test

analyze: ## Analyze (infos non-fatal; matches README verify)
	$(FLUTTER) analyze --no-fatal-infos

analyze-strict: ## Analyze with default analyzer severity (infos fatal)
	$(FLUTTER) analyze

fix: ## Apply automated fixes (`dart fix --apply`)
	$(DART) fix --apply

# --- Tests ---

test: get ## Run tests
	$(FLUTTER) test

# --- Codegen ---

codegen: get ## Run build_runner (auto_route, etc.)
	$(DART) run build_runner build --delete-conflicting-outputs

build-runner: codegen ## Alias for `codegen`

codegen-watch: get ## build_runner in watch mode
	$(DART) run build_runner watch --delete-conflicting-outputs

# --- Assets / tooling ---

icons: get ## Regenerate launcher icons (flutter_launcher_icons)
	$(DART) run flutter_launcher_icons

splash: get ## Regenerate native splash screens
	$(DART) run flutter_native_splash:create

# --- Clean ---

clean: ## `flutter clean`
	$(FLUTTER) clean

# --- Builds ---

build-apk-debug: get ## Debug APK
	$(FLUTTER) build apk --debug

build-apk-release: get ## Release APK
	$(FLUTTER) build apk --release

build-linux-debug: get ## Debug Linux binary
	$(FLUTTER) build linux --debug

build-linux-release: get ## Release Linux binary
	$(FLUTTER) build linux --release

build-macos: get ## Release macOS app
	$(FLUTTER) build macos --release

build-windows: get ## Release Windows app
	$(FLUTTER) build windows --release

build-web: get ## Release Web build
	$(FLUTTER) build web --release

deploy-web: ## Deploy `build/web` to Vercel (production)
	cd build/web && npx vercel@latest --prod

# --- CI-style pipeline ---

check: format-check analyze test ## format (check only) + analyze + test
