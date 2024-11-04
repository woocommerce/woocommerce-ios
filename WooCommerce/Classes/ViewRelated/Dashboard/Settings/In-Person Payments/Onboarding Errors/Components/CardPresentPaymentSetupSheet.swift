import SwiftUI

extension View {
    /// Displays a sheet that contains a webview to show a card present payment setup URL.
    /// The webview is pre-authenticated for merchants who log in with site credentials.
    func cardPresentPaymentSetupSheet(url: Binding<URL?>, dismiss: @escaping (() -> Void)) -> some View {
        self.modifier(CardPresentPaymentSetupSheet(url: url, dismiss: dismiss))
    }
}

struct CardPresentPaymentSetupSheet: ViewModifier {
    @Binding var url: URL?
    let dismiss: (() -> Void)

    func body(content: Content) -> some View {
        content
            .sheet(item: $url) { url in
                // For WPCOM login, wp-admin URL gets redirected to a WPCOM page in a webview and cannot be pre-authenticated easily.
                // For site credentials login, wp-admin URL can be pre-authenticated in a webview.
                // Therefore, authenticated webview is only enabled for site credentials login.
                WebViewSheet(viewModel: .init(url: url,
                                              navigationTitle: Localization.webviewSetupTitle,
                                              authenticated: ServiceLocator.stores.isAuthenticatedWithoutWPCom)) {
                    dismiss()
                }
            }
    }
}

private extension CardPresentPaymentSetupSheet {
    enum Localization {
        static let webviewSetupTitle = NSLocalizedString(
            "card.present.payment.setup.webview.title", value: "Payments Setup",
            comment: "Button to refresh the state of the in-person payments setup")
    }
}
