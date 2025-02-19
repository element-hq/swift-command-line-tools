import Darwin
import Foundation

public enum Zsh {
    enum Error: Swift.Error {
        case commandFailure(command: String, directory: URL?)
    }
    
    /// The currently running process, used to allow a SIGINT to terminate a long running task.
    private static var currentProcess: Process?
    
    /// A default directory to used when `run(command:)` is called without a directory specified.
    public static var defaultDirectory: URL?
    
    @discardableResult
    /// Runs the given command, waiting for it to complete before returning.
    /// - Parameters:
    ///   - command: The command to be run.
    ///   - directory: An optional working directory in which to run the command. When omitted, ``defaultDirectory`` will be used if set.
    ///   - captureStandardOutput: A flag to control whether or not the command output is captured or printed to the terminal
    /// - Returns: The output of the command if `captureStandardOutput == true` and the command printed something.
    public static func run(command: String, directory: URL? = nil, captureStandardOutput: Bool = true) throws -> String? {
        let process = Process()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-cu", command]
        process.currentDirectoryURL = directory ?? defaultDirectory
        
        if captureStandardOutput {
            process.standardOutput = outputPipe
        }
        
        currentProcess = process
        defer { currentProcess = nil }
        signal(SIGINT) { _ in Zsh.currentProcess?.terminate() }
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw Error.commandFailure(command: command, directory: directory ?? defaultDirectory)
        }
        
        guard captureStandardOutput, let outputData = try outputPipe.fileHandleForReading.readToEnd() else { return nil }
        return String(data: outputData, encoding: .utf8)
    }
}
