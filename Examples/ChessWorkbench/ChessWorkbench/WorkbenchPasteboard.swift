import AppKit

enum WorkbenchPasteboard {
    /// SwiftUI has no direct macOS clipboard writer, so this keeps the
    /// app-initiated pasteboard bridge isolated from the SwiftUI views.
    @discardableResult
    static func copy(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
