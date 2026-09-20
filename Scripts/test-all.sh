#!/usr/bin/env bash

#
# SwiftChessTools provides reusable chess rules, notation, UCI helpers, and SwiftUI board UI.
#
# See NOTICE.md for upstream attribution and license details.
#
# Licensed under the MIT License.
# You may obtain a copy of the License at: https://opensource.org/licenses/MIT
# See the LICENSE file for more information.
#

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

macos_destination="${MACOS_DESTINATION:-platform=macOS,arch=arm64}"

resolve_ios_destination() {
  if [[ -n "${IOS_DESTINATION:-}" ]]; then
    printf '%s' "$IOS_DESTINATION"
    return
  fi

  local simulator_name="${IOS_SIMULATOR_NAME:-iPhone 17 Pro}"
  local simulator_id
  simulator_id="$({
    xcrun simctl list devices available |
      awk -v name="$simulator_name" '
        {
          device = $0
          sub(/^[[:space:]]+/, "", device)
        }
        index(device, name " (") == 1 && match(device, /\([0-9A-F-]+\)/) {
          print substr(device, RSTART + 1, RLENGTH - 2)
          exit
        }
      '
  })"

  if [[ -z "$simulator_id" ]]; then
    printf 'No available iOS simulator named %s. Set IOS_SIMULATOR_NAME or IOS_DESTINATION.\n' "$simulator_name" >&2
    return 1
  fi

  printf 'platform=iOS Simulator,id=%s' "$simulator_id"
}

ios_destination="$(resolve_ios_destination)"

run() {
  printf '\n==> %s\n' "$1"
  shift
  "$@"
}

run "Swift package tests" \
  swift test

run "Release package build" \
  swift build -c release

run "ChessCore recipe smoke test" \
  swift run --package-path Examples/ChessCoreRecipes

if api_baseline="$(git describe --tags --abbrev=0 2>/dev/null)"; then
  run "Public API compatibility against $api_baseline" \
    swift package diagnose-api-breaking-changes "$api_baseline"
else
  printf '\n==> Public API compatibility skipped because no Git tag is available.\n'
fi

run "ChessUIHarness XCUITest" \
  xcodebuild \
    -project Tests/ChessUIHarness/ChessUIHarness.xcodeproj \
    -scheme ChessUIHarness \
    -configuration Debug \
    -destination "$ios_destination" \
    -derivedDataPath .build/xcode-harness \
    -clonedSourcePackagesDirPath .build/xcode-harness/SourcePackages \
    test

run "ChessWorkbench macOS UI tests" \
  xcodebuild \
    -project Examples/ChessWorkbench/ChessWorkbench.xcodeproj \
    -scheme ChessWorkbench \
    -configuration Debug \
    -destination "$macos_destination" \
    -derivedDataPath .build/xcode-chess-workbench \
    -clonedSourcePackagesDirPath .build/xcode-chess-workbench/SourcePackages \
    test

printf '\nAll SwiftChessTools validation checks passed.\n'
