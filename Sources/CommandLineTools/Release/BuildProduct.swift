import Foundation

/// Information about a the build product that is being released.
public struct BuildProduct {
    /// The source repo such as `matrix-org/matrix-rust-sdk`.
    public let sourceRepo: Repository
    /// The version of the package that was built.
    public let version: String
    /// The commit hash the product was built from.
    public let commitHash: String
    /// The branch the product was built from.
    public let branch: String
    /// The directory that contains the framework and generated sources.
    public let directory: URL
    /// The name of the built XCFramework such as `MatrixSDKFFI.xcframework`.
    public let frameworkName: String
    
    public init(sourceRepo: Repository, version: String, commitHash: String, branch: String, directory: URL, frameworkName: String) {
        self.sourceRepo = sourceRepo
        self.version = version
        self.commitHash = commitHash
        self.branch = branch
        self.directory = directory
        self.frameworkName = frameworkName
    }
}
