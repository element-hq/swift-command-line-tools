import Foundation

/// A local git repo.
public struct Git {
    /// Clone a repository into a new directory, creating a new `Git` instance.
    public static func clone(repository: URL, directory: URL) throws -> Git {
        if !FileManager.default.fileExists(atPath: directory.path()) {
            try Zsh.run(command: "git clone \(repository.absoluteURL) \(directory.path())")
        }
        return Git(directory: directory)
    }
    
    enum Error: Swift.Error {
        case noOutput
    }
    
    /// The directory of the repo.
    public let directory: URL
    
    public init(directory: URL) {
        self.directory = directory
    }
    
    /// The name of the current branch.
    public var branchName: String {
        get throws {
            guard let output = try Zsh.run(command: "git rev-parse --abbrev-ref HEAD", directory: directory) else { throw Error.noOutput }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// The hash of the current commit.
    public var commitHash: String {
        get throws {
            guard let output = try Zsh.run(command: "git rev-parse HEAD", directory: directory) else { throw Error.noOutput }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// Download objects and refs from another repository
    public func fetch() throws {
        try Zsh.run(command: "git fetch", directory: directory)
    }
    
    /// Switch branches or restore working tree files
    public func checkout(branch: String) throws {
        try Zsh.run(command: "git checkout \(branch)", directory: directory)
    }
    
    /// Add file contents to the index.
    public func add(files: String...) throws {
        try Zsh.run(command: "git add \(files.joined(separator: " "))", directory: directory)
    }
    
    /// Record changes to the repository.
    public func commit(message: String) throws {
        try Zsh.run(command: "git commit -m \"\(message)\"", directory: directory)
    }
    
    /// Update remote refs along with associated objects.
    public func push() throws {
        try Zsh.run(command: "git push", directory: directory)
    }
}
