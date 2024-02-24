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

    let viewModel: AuthenticatedWebViewModel

    init(isPresented: Binding<Bool>,
             viewModel: AuthenticatedWebViewModel) {
            self._isPresented = isPresented
            self.viewModel = viewModel
        }

    init(isPresented: Binding<Bool>,
             url: URL,
             urlToTriggerExit: String? = nil,
             exitTrigger: ((URL?) -> Void)? = nil) {
            self._isPresented = isPresented
            viewModel = DefaultAuthenticatedWebViewModel(initialURL: url,
                                                         urlToTriggerExit: urlToTriggerExit,
                                                         exitTrigger: exitTrigger)
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
                             url: URL(string: "https://www.woo.com")!)
    }
}
#endif
