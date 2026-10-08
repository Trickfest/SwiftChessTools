// Licensed under the MIT License. See LICENSE and NOTICE.md.
//
// Run from the package root with Xcode 27's SwiftBuild backend on Apple silicon:
// swift build -c release --target ChessCore
// timeline_build_dir="$(swift build -c release --show-bin-path)"
// swiftc -O -parse-as-library -target arm64-apple-macos26.0 -I "$timeline_build_dir" \
//   Scripts/benchmark-game-timeline.swift "$timeline_build_dir/ChessCore.o" \
//   -o .build/benchmark-game-timeline
// .build/benchmark-game-timeline
//
// These are diagnostic wall-clock measurements, not timing assertions. The
// repetitive 1,000-ply line intentionally continues beyond automatic draws.
// It measures replay overhead, not every possible position or device/UI latency.

import Foundation
import ChessCore

@main
struct TimelineBenchmark {
    static func main() throws {
        let cycle = try ["g1f3", "g8f6", "f3g1", "f6g8"].map(Move.init(string:))
        let line = Array(repeating: cycle, count: 250).flatMap { $0 }
        let timeline = try measure("Construct 1,000 plies", operations: 1) {
            try GameTimeline(moves: line)
        }
        let checksum = try measure("Navigate final 100 plies", operations: 100) {
            var count = 0
            for ply in (901...1000).reversed() {
                count += try timeline.game(atPly: ply).moveHistory.count
            }
            return count
        }
        precondition(checksum == (901...1000).reduce(0, +))
        let appended = try measure("Append 1,000 individual moves", operations: 1000) {
            var result = try GameTimeline()
            for move in line { try result.append(move) }
            return result
        }
        precondition(appended.moves == timeline.moves)
        precondition(appended.moveRecords == timeline.moveRecords)
        let replaced = try measure("Replace last 20 plies 30 times", operations: 30) {
            var result = timeline
            for _ in 0..<30 {
                try result.replaceContinuation(afterPly: 980, with: Array(line.suffix(20)))
            }
            return result
        }
        precondition(replaced.moveRecords == timeline.moveRecords)
        let end = try replaced.game(atPly: 1000)
        precondition(end.currentRepetitionCount == 251)
        print("Verified \(end.moveHistory.count) plies; end repetition count \(end.currentRepetitionCount).")
    }

    private static func measure<T>(_ name: String, operations: Int, _ operation: () throws -> T) rethrows -> T {
        let start = ProcessInfo.processInfo.systemUptime
        let result = try operation()
        let milliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1000
        print(String(format: "%@: %.2f ms total, %.2f ms/operation", name, milliseconds, milliseconds / Double(operations)))
        return result
    }
}
