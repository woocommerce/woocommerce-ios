import SwiftUI

/// Displays an authenticated web view with a navigation bar and a Done button.
struct WCAuthenticatedWebView: View {
    let url: URL
    let title: String
    let completion: () -> Void

    var body: some View {
        NavigationView {
            AuthenticatedWebView(isPresented: .constant(true),
                                 url: url)
                                 .navigationTitle(title)
                                 .navigationBarTitleDisplayMode(.inline)
                                 .toolbar {
                                     ToolbarItem(placement: .confirmationAction) {
                                         Button(action: {
                                             completion()
                                         }, label: {
                                             Text(Localization.done)
                                         })
                                     }
                                 }
        }
        .wooNavigationBarStyle()
        .navigationViewStyle(.stack)
    }
}

private extension WCAuthenticatedWebView {
    enum Localization {
        static let done = NSLocalizedString(
            "wcAuthenticatedWebView.done.button.title",
            value: "Done",
            comment: "Button title to dismiss the authenticated web view"
        )
    }
}

#Preview {
    WCAuthenticatedWebView(url: WooConstants.URLs.wooPaymentsStartupGuide.asURL(), title: "Preview", completion: {})
}
