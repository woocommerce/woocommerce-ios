import SwiftUI
import WebKit

/// A default view model for authenticated web view
///
final class DefaultAuthenticatedWebViewModel: AuthenticatedWebViewModel {
    let title: String
    let initialURL: URL?
    let urlToTriggerExit: String?
    let exitTrigger: (() -> Void)?

    init(title: String = "",
         initialURL: URL,
         urlToTriggerExit: String? = nil,
         exitTrigger: (() -> Void)? = nil) {
        self.title = title
        self.initialURL = initialURL
        self.urlToTriggerExit = urlToTriggerExit
        self.exitTrigger = exitTrigger
    }

    func handleDismissal() {
        // no-op
    }

    func handleRedirect(for url: URL?) {
        if let urlToTriggerExit,
            let url,
            url.absoluteString.contains(urlToTriggerExit) {
            exitTrigger?()
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
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

    let url: URL

    /// Optional URL or part of URL to trigger exit
    ///
    var urlToTriggerExit: String?

    /// Callback that will be triggered if the destination url containts the `urlToTriggerExit`
    ///
    var exitTrigger: (() -> Void)?

    func makeUIViewController(context: Context) -> AuthenticatedWebViewController {
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: url,
                                                         urlToTriggerExit: urlToTriggerExit,
                                                         exitTrigger: exitTrigger)
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
