import Foundation
import SwiftUI

final class PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel: ObservableObject, Identifiable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let settingsAdminUrl: URL
    // An unchanging, psuedo-random ID helps us correctly compare two copies which may have different closures.
    // This relies on the closures being immutable
    let id = UUID()

    @Published var shouldShowSettingsWebView: Bool = false

    @Published private(set) var primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? = nil
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    private let showsInAuthenticatedWebView: Bool
    private let retrySearchAction: () -> Void

    private var openSettingsButtonViewModel: CardPresentPaymentsModalButtonViewModel {
        CardPresentPaymentsModalButtonViewModel(
            title: Localization.openAdmin,
            actionHandler: { [weak self] in
                guard let self else { return }
                if showsInAuthenticatedWebView {
                    shouldShowSettingsWebView = true
                } else {
                    UIApplication.shared.open(settingsAdminUrl)
                }
                primaryButtonViewModel = retryButtonViewModel
            })
    }

    private var retryButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(settingsAdminUrl: URL,
         showsInAuthenticatedWebView: Bool,
         retrySearchAction: @escaping () -> Void,
         cancelSearchAction: @escaping () -> Void) {
        self.settingsAdminUrl = settingsAdminUrl
        self.showsInAuthenticatedWebView = showsInAuthenticatedWebView
        self.retrySearchAction = retrySearchAction
        self.retryButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.retry,
            actionHandler: retrySearchAction)
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelSearchAction)
        self.primaryButtonViewModel = openSettingsButtonViewModel
    }

    func settingsWebViewWasDismissed() {
        retrySearchAction()
    }
}

extension PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel: Hashable {
    static func == (lhs: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel,
                    rhs: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.imageName == rhs.imageName &&
        lhs.settingsAdminUrl == rhs.settingsAdminUrl &&
        lhs.shouldShowSettingsWebView == rhs.shouldShowSettingsWebView &&
        lhs.primaryButtonViewModel == rhs.primaryButtonViewModel &&
        lhs.cancelButtonViewModel == rhs.cancelButtonViewModel &&
        lhs.retryButtonViewModel == rhs.retryButtonViewModel &&
        lhs.showsInAuthenticatedWebView == rhs.showsInAuthenticatedWebView &&
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(imageName)
        hasher.combine(settingsAdminUrl)
        hasher.combine(shouldShowSettingsWebView)
        hasher.combine(primaryButtonViewModel)
        hasher.combine(cancelButtonViewModel)
        hasher.combine(retryButtonViewModel)
        hasher.combine(showsInAuthenticatedWebView)
        hasher.combine(id)
    }
}

private extension PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdateAddress.title",
            value: "Please correct your store address to proceed",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to address problems"
        )

        static let openAdmin = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdateAddress.openSettings.button.title",
            value: "Enter Address",
            comment: "Button to open a webview at the admin pages, so that the merchant can update their store address " +
            "to continue setting up In Person Payments"
        )

        static let retry = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdateAddress.retry.button.title",
            value: "Retry After Updating",
            comment: "Button to try again after connecting to a specific reader fails due to address problems. " +
            "Intended for use after the merchant corrects the address in the store admin pages."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdateAddress.cancel.button.title",
            value: "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to address " +
            "problems. This also cancels searching."
        )
    }
}
