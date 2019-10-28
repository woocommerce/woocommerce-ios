import Foundation

public final class ProductPreviewGenerator: NSObject {
    private let product: Product
    private let frameNonce: String?
    private let authenticator: WebViewAuthenticator

    public typealias PreviewGenerationCompletion = (_ urlRequest: URLRequest?, _ errorMessage: String?) -> Void

    public init(product: Product, frameNonce: String?, credentials: Credentials) {
        self.product = product
        self.frameNonce = frameNonce
        authenticator = WebViewAuthenticator(credentials: credentials)
        super.init()
    }

    public func generate(completion: @escaping PreviewGenerationCompletion) {
        guard let url = URL(string: product.permalink) else {
            handlePreviewRequestFailed(reason: "preview failed because post permalink is unexpectedly nil", completion: completion)
            return
        }
        attemptPreview(url: url, completion: completion)
    }
}

// MARK: - Error handling
//
private extension ProductPreviewGenerator {
    func handlePreviewRequestFailed(reason: String, completion: PreviewGenerationCompletion) {
        DDLogError("⚠️ Preview failed: \(reason)")
        let message = NSLocalizedString("There has been an error while trying to reach your site.", comment: "An error message.")
        completion(nil, message)
    }
}


// MARK: - Authentication

private extension ProductPreviewGenerator {
    func attemptPreview(url: URL, completion: @escaping PreviewGenerationCompletion) {
        switch authenticationRequired {
        case .nonce(let frameNonce):
            attemptNonceAuthenticatedRequest(url: url, nonce: frameNonce, completion: completion)
        case .cookie:
            attemptCookieAuthenticatedRequest(url: url, completion: completion)
        case .none:
            attemptUnauthenticatedRequest(url: url, completion: completion)
        }
    }

    var authenticationRequired: Authentication {
        guard needsLogin() else {
            return .none
        }
        if let frameNonce = frameNonce {
            return .nonce(frameNonce: frameNonce)
        } else {
            return .cookie
        }
    }

    enum Authentication {
        case nonce(frameNonce: String)
        case cookie
        case none
    }

    func needsLogin() -> Bool {
        let status = product.productStatus
        switch status {
        case .draft, .privateStatus, .pending, .publish:
            return true
        default:
            return false
        }
    }

    func attemptUnauthenticatedRequest(url: URL, completion: PreviewGenerationCompletion) {
        let request = URLRequest(url: url)
        completion(request, nil)
    }

    func attemptNonceAuthenticatedRequest(url: URL, nonce: String, completion: PreviewGenerationCompletion) {
        guard let authenticatedUrl = addNonce(nonce, to: url) else {
                handlePreviewRequestFailed(reason: "preview failed because url with nonce is unexpectedly nil", completion: completion)
                return
        }
        let request = URLRequest(url: authenticatedUrl)
        completion(request, nil)
    }

    func attemptCookieAuthenticatedRequest(url: URL, completion: @escaping PreviewGenerationCompletion) {
        authenticator.request(url: url, cookieJar: HTTPCookieStorage.shared) { request in
            completion(request, nil)
        }
    }
}

private extension ProductPreviewGenerator {
    func addNonce(_ nonce: String, to url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "preview", value: "true"))
        queryItems.append(URLQueryItem(name: "frame-nonce", value: nonce))
        components.queryItems = queryItems
        return components.url
    }
}
