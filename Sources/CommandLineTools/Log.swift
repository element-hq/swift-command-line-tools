import Foundation
import OSLog

public struct Log {
    /// Logs a release message.
    public static func info(_ message: String) {
        print("🚀 \(message)")
    }
}
