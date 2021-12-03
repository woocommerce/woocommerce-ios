import UIKit
import SwiftUI
import Yosemite

/// Modal presented when an error occurs while connecting to a reader due to problems with the address
///
final class CardPresentModalConnectingFailedUpdateAddress: CardPresentPaymentsModalViewModel {
    private var adminUrl: URL?
    private let openUrlInSafariAction: (_ url: URL) -> Void
    private let retrySearchAction: () -> Void
    private let cancelSearchAction: () -> Void
    private let site: Site?

    @State private var showingUpdateAddressWebView: Bool = false

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    var primaryButtonTitle: String? {
        guard adminUrl != nil else {
            return Localization.retry
        }
        return Localization.openAdmin
    }

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(adminUrl: URL?,
         site: Site?,
         openUrlInSafari: @escaping (URL) -> Void,
         retrySearch: @escaping () -> Void,
         cancelSearch: @escaping () -> Void) {
        self.adminUrl = adminUrl
        self.site = site
        self.openUrlInSafariAction = openUrlInSafari
        self.retrySearchAction = retrySearch
        self.cancelSearchAction = cancelSearch
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let adminUrl = adminUrl,
              let viewController = viewController else {
            return retrySearchAction()
        }
        switch site?.isWordPressStore {
        case true:
            presentAuthenticatedWebview(url: adminUrl, from: viewController)
        default:
            self.openUrlInSafariAction(adminUrl)
        }
    }

    private func presentAuthenticatedWebview(url adminUrl: URL, from viewController: UIViewController) {
        let nav = NavigationView {
            AuthenticatedWebView(isPresented: .constant(true),
                                 url: adminUrl,
                                 urlToTriggerExit: nil) { [weak self] in
                self?.showingUpdateAddressWebView = false
                self?.retrySearchAction()
            }
                                 .navigationTitle(Localization.adminWebviewTitle)
                                 .navigationBarTitleDisplayMode(.inline)
                                 .toolbar {
                                     ToolbarItem(placement: .confirmationAction) {
                                         Button(action: { [weak self] in
                                             viewController.dismiss(animated: true) {
                                                 self?.retrySearchAction()
                                             }
                                         }, label: {
                                             Text(Localization.doneButtonUpdateAddress)
                                         })
                                     }
                                 }
        }
            .wooNavigationBarStyle()
        let hostingController = UIHostingController(rootView: nav)
        viewController.present(hostingController, animated: true, completion: nil)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelSearchAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalConnectingFailedUpdateAddress {
    enum Localization {
        static let title = NSLocalizedString(
            "Please correct your store address to proceed",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to address problems"
        )

        static let adminWebviewTitle = NSLocalizedString(
            "WooCommerce Settings",
            comment: "Navigation title of the webview which used by the merchant to update their store address"
        )

        static let openAdmin = NSLocalizedString(
            "Enter Address",
            comment: "Button to open a webview at the admin pages, so that the merchant can update their store address " +
            "to continue setting up In Person Payments"
        )

        static let retry = NSLocalizedString(
            "Retry After Updating",
            comment: "Button to try again after connecting to a specific reader fails due to address problems. " +
            "Intended for use after the merchant corrects the address in the store admin pages."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to address " +
            "problems. This also cancels searching."
        )

        static let doneButtonUpdateAddress = NSLocalizedString(
            "Done",
            comment: "The button title to indicate that the user has finished updating their store's address and is" +
            "ready to close the webview. This also tries to connect to the reader again."
        )
    }
}
