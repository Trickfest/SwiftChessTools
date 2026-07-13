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

run() {
  printf '\n==> %s\n' "$1"
  shift
  "$@"
}

run "Swift package tests" \
  swift test

run "Release package build" \
  swift build -c release

run "Source package build for generic iOS hardware" \
  xcodebuild \
    -scheme SwiftChessTools-Package \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    -derivedDataPath .build/xcode-ci-ios \
    CODE_SIGNING_ALLOWED=NO \
    build

run "ChessCore recipe smoke test" \
  swift run --package-path Examples/ChessCoreRecipes

if api_baseline="$(git describe --tags --abbrev=0 2>/dev/null)"; then
  run "Public API compatibility against $api_baseline" \
    swift package diagnose-api-breaking-changes "$api_baseline"
else
  printf '\n==> Public API compatibility skipped because no Git tag is available.\n'
fi

printf '\nAll SwiftChessTools hosted CI checks passed.\n'
