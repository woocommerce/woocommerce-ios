import SwiftUI
import WebKit

/// A default view model for authenticated web view
///
final class DefaultAuthenticatedWebViewModel: AuthenticatedWebViewModel {
    let title: String
    let initialURL: URL?
    let urlToTriggerExit: String?
    let exitTrigger: ((URL?) -> Void)?

    init(title: String = "",
         initialURL: URL,
         urlToTriggerExit: String? = nil,
         exitTrigger: ((URL?) -> Void)? = nil) {
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
            exitTrigger?(url)
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

    private let viewModel: AuthenticatedWebViewModel
    private let skipsAuthentication: Bool

    init(isPresented: Binding<Bool>,
         viewModel: AuthenticatedWebViewModel,
         skipsAuthentication: Bool = false) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self.skipsAuthentication = skipsAuthentication
    }

    init(isPresented: Binding<Bool>,
         url: URL,
         urlToTriggerExit: String? = nil,
         exitTrigger: ((URL?) -> Void)? = nil) {
        self._isPresented = isPresented
        viewModel = DefaultAuthenticatedWebViewModel(initialURL: url,
                                                     urlToTriggerExit: urlToTriggerExit,
                                                     exitTrigger: exitTrigger)
        skipsAuthentication = false
    }

    func makeUIViewController(context: Context) -> AuthenticatedWebViewController {
        return AuthenticatedWebViewController(viewModel: viewModel,
                                              skipsAuthentication: skipsAuthentication)
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
