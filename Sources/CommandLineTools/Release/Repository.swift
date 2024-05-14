import Foundation

/// Represents a repository on GitHub.
public struct Repository: Codable {
    /// The repository's owner such as `element-hq`.
    public let owner: String
    /// The repository's name such as `swift-command-line-tools`.
    public let name: String
    
    public init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }
}
