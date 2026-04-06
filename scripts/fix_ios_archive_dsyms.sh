#!/bin/sh

set -eu

archive_path="${1:-build/ios/archive/Runner.xcarchive}"
apps_path="$archive_path/Products/Applications"
dsyms_path="$archive_path/dSYMs"

if [ ! -d "$apps_path" ]; then
  echo "Archive applications directory not found: $apps_path" >&2
  exit 1
fi

mkdir -p "$dsyms_path"

find "$apps_path" -type d -path '*/Frameworks/*.framework' | while IFS= read -r framework_path; do
  framework_name="$(basename "$framework_path" .framework)"
  binary_path="$framework_path/$framework_name"
  dsym_path="$dsyms_path/$framework_name.framework.dSYM"

  if [ ! -f "$binary_path" ] || [ -d "$dsym_path" ]; then
    continue
  fi

  echo "Generating dSYM for $framework_name.framework"
  xcrun dsymutil -o "$dsym_path" "$binary_path"

  binary_uuid="$(xcrun dwarfdump --uuid "$binary_path" | awk 'NR==1 { print $2 }')"
  dsym_uuid="$(xcrun dwarfdump --uuid "$dsym_path" | awk 'NR==1 { print $2 }')"

  if [ -z "$binary_uuid" ] || [ "$binary_uuid" != "$dsym_uuid" ]; then
    echo "dSYM UUID mismatch for $framework_name.framework" >&2
    exit 1
  fi
done
