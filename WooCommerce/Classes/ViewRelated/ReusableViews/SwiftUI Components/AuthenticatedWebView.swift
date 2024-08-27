import SwiftUI
import WebKit

/// A default view model for authenticated web view
///
final class DefaultAuthenticatedWebViewModel: AuthenticatedWebViewModel {
    let title: String
    let initialURL: URL?

    /// Optional closure for when the web page loads the initial URL successfully.
    let pageLoadHandler: ((URL) -> Void)?

    /// A url to trigger dismissing of the web view.
    let urlToTriggerExit: String?

    /// Closure to determine the action given the redirect URL.
    /// If `urlToTriggerExit` is provided, this closure is triggered only when
    /// a redirect URL matches `urlToTriggerExit`.
    /// Otherwise, the closure is triggered whenever the web view redirects to a new URL.
    let redirectHandler: ((URL) -> Void)?

    /// Optional closure for when a web page fails to load.
    let errorHandler: ((Error) -> Void)?

    init(title: String = "",
         initialURL: URL,
         urlToTriggerExit: String? = nil,
         pageLoadHandler: ((URL) -> Void)? = nil,
         redirectHandler: ((URL) -> Void)? = nil,
         errorHandler: ((Error) -> Void)? = nil) {
        self.title = title
        self.initialURL = initialURL
        self.urlToTriggerExit = urlToTriggerExit
        self.pageLoadHandler = pageLoadHandler
        self.redirectHandler = redirectHandler
        self.errorHandler = errorHandler
    }

    func handleDismissal() {
        // no-op
    }

    func handleRedirect(for url: URL?) {
        guard let url else {
            return
        }
        guard let urlToTriggerExit else {
            // always trigger `redirectHandler` if `urlToTriggerExit` is not specified.
            redirectHandler?(url)
            return
        }
        if url.absoluteString.contains(urlToTriggerExit) {
            redirectHandler?(url)
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }

    func didFinishNavigation(for url: URL) {
        pageLoadHandler?(url)
    }

    func didFailProvisionalNavigation(with error: Error) {
        errorHandler?(error)
    }
}


// Bridge UIKit `WKWebView` component to SwiftUI for URLs that need authentication on WPCom
struct AuthenticatedWebView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    @Binding var isPresented: Bool {
        didSet {
            if !isPresented {
                presentation.wrappedValue.dismiss()
            }
        }
    }

    let viewModel: AuthenticatedWebViewModel

    init(isPresented: Binding<Bool>,
         viewModel: AuthenticatedWebViewModel) {
        self._isPresented = isPresented
        self.viewModel = viewModel
    }

    init(isPresented: Binding<Bool>,
         url: URL,
         urlToTriggerExit: String? = nil,
         redirectHandler: ((URL) -> Void)? = nil) {
            self._isPresented = isPresented
            viewModel = DefaultAuthenticatedWebViewModel(initialURL: url,
                                                         urlToTriggerExit: urlToTriggerExit,
                                                         redirectHandler: redirectHandler)
        }

    func makeUIViewController(context: Context) -> AuthenticatedWebViewController {
        return AuthenticatedWebViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: AuthenticatedWebViewController, context: Context) {
        // no-op
    }
}

#if DEBUG
struct AuthenticatedWebView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedWebView(isPresented: .constant(true),
                             url: URL(string: "https://www.woocommerce.com")!)
    }
}
#endif
