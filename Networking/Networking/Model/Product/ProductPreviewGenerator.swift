import Foundation

extension URL {
    func appendingHideMasterbarParameters() -> URL? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        // FIXME: This code is commented out because of a menu navigation issue that can occur while
        // viewing a site within the webview. See https://github.com/wordpress-mobile/WordPress-iOS/issues/9796
        // for more details.
        //
        // var queryItems = components.queryItems ?? []
        // queryItems.append(URLQueryItem(name: "preview", value: "true"))
        // queryItems.append(URLQueryItem(name: "iframe", value: "true"))
        // components.queryItems = queryItems
        /////
        return components.url
    }
}

public final class ProductPreviewGenerator: NSObject {
    let product: Product
    private let frameNonce: String?
    fileprivate let authenticator: WebViewAuthenticator?

    public var onAttemptURLRequest: ((URLRequest) -> Void)?
    public var onFailure: ((String) -> Void)?

    public init(product: Product, frameNonce: String?, credentials: Credentials) {
        self.product = product
        self.frameNonce = frameNonce
        authenticator = WebViewAuthenticator(credentials: credentials)
        super.init()
    }

    public func generate() {
        guard let url = URL(string: product.permalink) else {
            previewRequestFailed(reason: "preview failed because post permalink is unexpectedly nil")
            return
        }
        attemptPreview(url: url)
    }

    @objc func previewRequestFailed(reason: String) {
//        let message = "Preview failed"
//        let properties = ["reason": reason]
//        CrashLogging.logMessage(message, properties: properties)
        let message = NSLocalizedString("There has been an error while trying to reach your site.", comment: "An error message.")
        onFailure?(message)
    }

    @objc func interceptRedirect(request: URLRequest) -> URLRequest? {
        return authenticator?.interceptRedirect(request: request)
    }
}


// MARK: - Authentication

private extension ProductPreviewGenerator {
    func attemptPreview(url: URL) {

        // Attempt to append params. If that fails, fall back to the original url.
        let url = url.appendingHideMasterbarParameters() ?? url

        switch authenticationRequired {
        case .nonce:
            attemptNonceAuthenticatedRequest(url: url)
        case .cookie:
            attemptCookieAuthenticatedRequest(url: url)
        case .none:
            attemptUnauthenticatedRequest(url: url)
        }
    }

    var authenticationRequired: Authentication {
        guard needsLogin() else {
            return .none
        }
        if frameNonce != nil {
            return .nonce
        } else {
            return .cookie
        }
    }

    enum Authentication {
        case nonce
        case cookie
        case none
    }

    func needsLogin() -> Bool {
        let status = product.productStatus
        switch status {
//        case .draft, .privateStatus, .pending, .scheduled, .publish:
        case .draft, .privateStatus, .pending, .publish:
            return true
        default:
            return false
        }
    }

    func attemptUnauthenticatedRequest(url: URL) {
        let request = URLRequest(url: url)

        onAttemptURLRequest?(request)
    }

    func attemptNonceAuthenticatedRequest(url: URL) {
        guard let nonce = frameNonce,
            let authenticatedUrl = addNonce(nonce, to: url) else {
                previewRequestFailed(reason: "preview failed because url with nonce is unexpectedly nil")
                return
        }
        let request = URLRequest(url: authenticatedUrl)

        onAttemptURLRequest?(request)
    }

    func attemptCookieAuthenticatedRequest(url: URL) {
        guard let authenticator = authenticator else {
            previewRequestFailed(reason: "preview failed because authenticator is unexpectedly nil")
            return
        }
        authenticator.request(url: url, cookieJar: HTTPCookieStorage.shared, completion: { [weak self] request in

            self?.onAttemptURLRequest?(request)
        })
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
