import Foundation
import Yosemite
import WebKit
import WooFoundation

struct PurchaseCardReaderWebViewViewModel: AuthenticatedWebViewModel {
    var title: String

    var initialURL: URL?

    let onDismiss: () -> Void

    init(configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         utmProvider: UTMParametersProviding,
         onDismiss: @escaping () -> Void) {
        self.title = Localization.title
        self.initialURL = configuration.purchaseCardReaderUrl(utmProvider: utmProvider)
        self.onDismiss = onDismiss
    }

    func handleDismissal() {
        onDismiss()
    }

    func handleRedirect(for url: URL?) {

    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        return .allow
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Order Card Reader",
        comment: "Title for the webview used by merchants to place an order for a card reader, for use with " +
        "In-Person Payments.")
}
