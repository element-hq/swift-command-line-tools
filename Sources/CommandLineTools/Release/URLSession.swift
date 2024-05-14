import Foundation

extension URLSession {
    /// Returns a URLSession that mocks responses to creating a release and uploading the release asset.
    public static var releaseMock: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [ReleaseMockURLProtocol.self] + (configuration.protocolClasses ?? [])
        let result = URLSession(configuration: configuration)
        return result
    }
}

private class ReleaseMockURLProtocol: URLProtocol {
    static let uploadURLString = URL(string: "https://api.github.com/upload")!
    
    override func startLoading() {
        if isReleaseRequest {
            let response = GitHubRelease(htmlURL: URL(string: "https://github.com/owner/repo/release/v1.0.0")!,
                                         uploadURLString: ReleaseMockURLProtocol.uploadURLString.absoluteString)
            if let data = try? JSONEncoder().encode(response),
               let urlResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil) {
                client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .allowedInMemoryOnly)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
                return
            }
        } else if isUploadRequest {
            let response = GitHubUploadResponse(browserDownloadURL: "https://github.com/owner/repo/release/framework.zip")
            if let data = try? JSONEncoder().encode(response),
               let urlResponse = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil) {
                client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .allowedInMemoryOnly)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
                return
            }
        }
        
        client?.urlProtocol(self, didFailWithError: NSError(domain: "URLProtocol", code: -1))
    }

    override func stopLoading() {
        //  no-op
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    // MARK: -
    
    private var isReleaseRequest: Bool {
        guard let url = request.url, url.path().hasPrefix("/repos"), url.path().hasSuffix("/releases") else {
            return false
        }
        
        return true
    }
    
    private var isUploadRequest: Bool {
        guard let url = request.url, url.path() == ReleaseMockURLProtocol.uploadURLString.path() else {
            return false
        }
        
        return true
    }
}
