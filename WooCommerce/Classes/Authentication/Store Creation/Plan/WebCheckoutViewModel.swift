import WebKit

/// View model used for the web view controller to check out.
final class WebCheckoutViewModel: AuthenticatedWebViewModel {
    // `AuthenticatedWebViewModel` protocol conformance.
    let title = Localization.title
    let initialURL: URL?

    /// Keeps track of whether the completion has been triggered so that it's only invoked once.
    /// There are usually multiple redirects with the same success URL prefix.
    private var isComplete: Bool = false

    private let completion: () -> Void

    /// - Parameters:
    ///   - siteSlug: The slug of the site URL that the web checkout is for.
    ///   - completion: Invoked when the webview reaches the success URL.
    init(siteSlug: String, completion: @escaping () -> Void) {
        self.initialURL = URL(string: String(format: Constants.checkoutURLFormat, siteSlug))
        self.completion = completion
    }

    func handleDismissal() {
        // no-op: dismissal is handled in the close button in the navigation bar.
    }

    func handleRedirect(for url: URL?) {
        guard let path = url?.absoluteString else {
            return
        }
        handleCompletionIfPossible(path)
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        handleCompletionIfPossible(navigationURL.absoluteString)
        return .allow
    }
}

private extension WebCheckoutViewModel {
    func handleCompletionIfPossible(_ url: String) {
        guard url.starts(with: Constants.completionURLPrefix) else {
            return
        }
        // Running on the main thread is necessary if this method is triggered from `decidePolicy`.
        DispatchQueue.main.async { [weak self] in
            self?.handleSuccess()
        }
    }

    func handleSuccess() {
        guard isComplete == false else {
            return
        }
        completion()
        isComplete = true
    }
}

private extension WebCheckoutViewModel {
    enum Constants {
        static let checkoutURLFormat = "https://wordpress.com/checkout/%@"
        static let completionURLPrefix = "https://wordpress.com/checkout/thank-you/"
    }

    enum Localization {
        static let title = NSLocalizedString("Checkout", comment: "Title of the WPCOM checkout web view.")
    }
}
