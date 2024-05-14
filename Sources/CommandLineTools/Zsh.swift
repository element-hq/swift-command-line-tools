import Foundation

public enum Zsh {
    enum Error: Swift.Error {
        case commandFailure(command: String, directory: URL?)
    }
    
    /// A default directory to used when `run(command:)` is called without a directory specified.
    public static var defaultDirectory: URL?
    
    @discardableResult
    /// Runs the given command, waiting for it to complete before returning.
    /// - Parameters:
    ///   - command: The command to be run.
    ///   - directory: An optional working directory in which to run the command. When omitted, ``defaultDirectory`` will be used if set.
    /// - Returns: The output of the command if any.
    public static func run(command: String, directory: URL? = nil) throws -> String? {
        let process = Process()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-cu", command]
        process.currentDirectoryURL = directory ?? defaultDirectory
        process.standardOutput = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw Error.commandFailure(command: command, directory: directory ?? defaultDirectory)
        }
        
        guard let outputData = try outputPipe.fileHandleForReading.readToEnd() else { return nil }
        return String(data: outputData, encoding: .utf8)
    }
}
