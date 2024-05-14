import Foundation
import CryptoKit

/// A Swift package that contains a binary target built from a Rust crate.
public struct Package {
    public enum Error: Swift.Error {
        case httpResponse(Int)
    }
    
    /// The API token used to make releases on GitHub.
    private let apiToken: String
    
    /// The repository that hosts this package.
    public let repository: Repository
    /// The local directory that the repository is cloned in.
    public let directory: URL
    
    public init(repository: Repository, directory: URL, apiToken: String) {
        self.repository = repository
        self.directory = directory
        self.apiToken = apiToken
    }
    
    /// Zips up the XCFramework from the given product, returning the file's URL and checksum.
    public func zipBinary(with product: BuildProduct) throws -> (URL, String) {
        let zipFileURL = directory.appending(component: "\(product.frameworkName).zip")
        if FileManager.default.fileExists(atPath: zipFileURL.path()) {
            Log.info("Deleting old framework")
            try FileManager.default.removeItem(at: zipFileURL)
        }

        Log.info("Zipping framework")
        try Zsh.run(command: "zip -r '\(zipFileURL.path())' \(product.frameworkName)", directory: product.directory)
        let checksum = try checksum(for: zipFileURL)
        Log.info("Checksum: \(checksum)")
        
        return (zipFileURL, checksum)
    }
    
    /// Updates the package's manifest to match the information from the given product and checksum.
    public func updateManifest(with product: BuildProduct, checksum: String) async throws {
        Log.info("Updating manifest")
        let manifestURL = directory.appending(component: "Package.swift")
        var updatedManifest = ""
        
        #warning("Strips empty lines")
        for try await line in manifestURL.lines {
            if line.starts(with: "let version = ") {
                updatedManifest.append("let version = \"\(product.version)\"")
            } else if line.starts(with: "let checksum = ") {
                updatedManifest.append("let checksum = \"\(checksum)\"")
            } else {
                updatedManifest.append(line)
            }
            updatedManifest.append("\n")
        }
        
        try updatedManifest.write(to: manifestURL, atomically: true, encoding: .utf8)
    }
    
    /// Creates a release on GitHub for the given product, with the zip of the XCFramework.
    public func makeRelease(with product: BuildProduct, uploading zipFileURL: URL) async throws {
        Log.info("Making release")
        let url = URL(string: "https://api.github.com/repos")!
            .appending(component: repository.owner)
            .appending(component: repository.name)
            .appending(component: "releases")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content")
        
        let body = GitHubReleaseRequest(tagName: product.version,
                                        targetCommitish: "main",
                                        name: product.version,
                                        body: "https://github.com/\(product.sourceRepo.owner)/\(product.sourceRepo.name)/tree/\(product.commitHash)",
                                        draft: false,
                                        prerelease: false,
                                        generateReleaseNotes: false,
                                        makeLatest: "true")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        
        Log.info("Release created \(release.htmlURL)")
        
        try await uploadFramework(at: zipFileURL, to: release.uploadURL)
    }
    
    // MARK: -
    
    private func uploadFramework(at fileURL: URL, to uploadURL: URL) async throws {
        Log.info("Uploading framework")
        
        var uploadComponents = URLComponents(url: uploadURL, resolvingAgainstBaseURL: false)!
        uploadComponents.queryItems = [URLQueryItem(name: "name", value: fileURL.lastPathComponent)]
        
        var request = URLRequest(url: uploadComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/zip", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.httpResponse(-1)
        }
        guard httpResponse.statusCode == 201 else {
            throw Error.httpResponse(httpResponse.statusCode)
        }
        
        let upload = try JSONDecoder().decode(GitHubUploadResponse.self, from: data)
        Log.info("Upload finished \(upload.browserDownloadURL)")
    }
    
    private func checksum(for fileURL: URL) throws -> String {
        var hasher = SHA256()
        let handle = try FileHandle(forReadingFrom: fileURL)
        
        while let bytes = try handle.read(upToCount: SHA256.blockByteCount) {
            hasher.update(data: bytes)
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - GitHub Release https://docs.github.com/en/rest/releases/releases#create-a-release

struct GitHubReleaseRequest: Encodable {
    let tagName: String
    let targetCommitish: String
    let name: String
    let body: String
    let draft: Bool
    let prerelease: Bool
    let generateReleaseNotes: Bool
    let makeLatest: String
}

struct GitHubRelease: Decodable {
    let htmlURL: URL
    let uploadURLString: String // Decode as a string to avoid URL percent encoding.
    
    var uploadURL: URL {
        URL(string: String(uploadURLString.split(separator: "{")[0]))!
    }
    
    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case uploadURLString = "upload_url"
    }
}

struct GitHubUploadResponse: Decodable {
    let browserDownloadURL: String
    
    enum CodingKeys: String, CodingKey {
        case browserDownloadURL = "browser_download_url"
    }
}
