#!/usr/bin/env bash

#
# SwiftChessTools provides reusable chess rules, notation, and SwiftUI board UI.
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

ios_destination="${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
macos_destination="${MACOS_DESTINATION:-platform=macOS,arch=arm64}"

run() {
  printf '\n==> %s\n' "$1"
  shift
  "$@"
}

run "Swift package tests" \
  swift test

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

printf '\nAll SwiftChessTools automated tests passed.\n'
