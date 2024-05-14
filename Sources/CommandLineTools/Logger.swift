import Foundation
import OSLog

public struct Log {
    private static let logger = Logger(subsystem: "io.element.swift-tools", category: "Release")
    
    /// Logs a release message.
    public static func info(_ message: String) {
        logger.info("🚀 \(message)")
    }
}
