import SwiftUI

/// Displays WooCommerce settings in a web view within a navigation view.
struct WCSettingsWebView: View {
    let adminUrl: URL
    let completion: () -> Void

    var body: some View {
        NavigationView {
            AuthenticatedWebView(isPresented: .constant(true),
                                 url: adminUrl)
                                 .navigationTitle(Localization.adminWebviewTitle)
                                 .navigationBarTitleDisplayMode(.inline)
                                 .toolbar {
                                     ToolbarItem(placement: .confirmationAction) {
                                         Button(action: {
                                             completion()
                                         }, label: {
                                             Text(Localization.doneButtonUpdateAddress)
                                         })
                                     }
                                 }
        }
        .wooNavigationBarStyle()
        .navigationViewStyle(.stack)
    }
}

private extension WCSettingsWebView {
    enum Localization {
        static let adminWebviewTitle = NSLocalizedString(
            "WooCommerce Settings",
            comment: "Navigation title of the webview which used by the merchant to update their store address"
        )

        static let doneButtonUpdateAddress = NSLocalizedString(
            "Done",
            comment: "The button title to indicate that the user has finished updating their store's address and is" +
            "ready to close the webview. This also tries to connect to the reader again."
        )
    }
}

#Preview {
    WCSettingsWebView(adminUrl: WooConstants.URLs.wooPaymentsStartupGuide.asURL(), completion: {})
}
