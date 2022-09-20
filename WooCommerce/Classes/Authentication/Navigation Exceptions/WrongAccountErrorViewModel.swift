import UIKit
import SafariServices
import Combine
import WordPressUI
import Yosemite
import WordPressAuthenticator

/// Configuration and actions for an ULErrorViewController, modelling
/// an error when Jetpack is not installed or is not connected
final class WrongAccountErrorViewModel: ULAccountMismatchViewModel {

    private let siteURL: String
    private let showsConnectedStores: Bool
    private let defaultAccount: Account?
    private let storesManager: StoresManager

    private var storePickerCoordinator: StorePickerCoordinator?

    private let primaryButtonHiddenSubject = CurrentValueSubject<Bool, Never>(true)
    private let primaryButtonLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let activityIndicatorLoadingSubject = CurrentValueSubject<Bool, Never>(false)

    init(siteURL: String?,
         showsConnectedStores: Bool,
         sessionManager: SessionManagerProtocol =  ServiceLocator.stores.sessionManager,
         storesManager: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL ?? Localization.yourSite
        self.showsConnectedStores = showsConnectedStores
        self.defaultAccount = sessionManager.defaultAccount
        self.storesManager = storesManager
    }

    // MARK: - Data and configuration
    var userEmail: String {
        guard let account = defaultAccount else {
            DDLogWarn("⚠️ Present account mismatch UI for \(siteURL) without a default account")

            return ""
        }
        return account.email
    }

    var userName: String {
        guard let account = defaultAccount else {
            DDLogWarn("⚠️ Present account mismatch UI for \(siteURL) without a default account")

            return ""
        }

        return account.displayName
    }

    var signedInText: String {
        guard let account = defaultAccount else {
            DDLogWarn("⚠️ Present account mismatch UI for \(siteURL) without a default display account")

            return ""
        }

        return String.localizedStringWithFormat(Localization.signedInMessageFormat,
                                                account.username)
    }

    let logOutTitle: String = Localization.wrongAccountMessage

    let logOutButtonTitle: String = Localization.logOutButtonTitle

    let image: UIImage = .productErrorImage

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                           attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonHidden = false

    let auxiliaryButtonTitle = Localization.findYourConnectedEmail

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    var isPrimaryButtonHidden: AnyPublisher<Bool, Never> {
        primaryButtonHiddenSubject.eraseToAnyPublisher()
    }

    var isPrimaryButtonLoading: AnyPublisher<Bool, Never> {
        primaryButtonLoadingSubject.eraseToAnyPublisher()
    }

    var isSecondaryButtonHidden: Bool { !showsConnectedStores }

    var isShowingActivityIndicator: AnyPublisher<Bool, Never> {
        activityIndicatorLoadingSubject.eraseToAnyPublisher()
    }

    // MARK: - Actions
    func viewDidLoad(_ viewController: UIViewController?) {
        fetchSiteInfo()
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        // TODO:
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .listStores)
        storePickerCoordinator?.start()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        let fancyAlert = FancyAlertViewController.makeNeedHelpFindingEmailAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)
    }

    func didTapLogOutButton(in viewController: UIViewController?) {
        // Log out and pop
        storesManager.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - Private helpers
private extension WrongAccountErrorViewModel {
    func fetchSiteInfo() {
        activityIndicatorLoadingSubject.send(true)
        WordPressAuthenticator.fetchSiteInfo(for: siteURL) { [weak self] result in
            guard let self = self else { return }
            self.activityIndicatorLoadingSubject.send(false)

            switch result {
            case .success(let siteInfo):
                if siteInfo.isWPCom == false {
                    self.primaryButtonHiddenSubject.send(false)
                }
            case .failure(let error):
                DDLogWarn("⚠️ Error fetching site info: \(error)")
            }
        }
    }
}


// MARK: - Private data structures
private extension WrongAccountErrorViewModel {
    enum Localization {
        static let signedInMessageFormat = NSLocalizedString("Signed in as @%1$@",
                                                             comment: "Message describing the account a user has signed in to."
                                                                + "Reads as: Signed is as @{username}"
                                                                + "Parameters: %1$@ - user name")

        static let errorMessage = NSLocalizedString("It looks like %@ is connected to a different account.",
                                                    comment: "Message explaining that the site entered and the acount logged into do not match. "
                                                        + "Reads like 'It looks like awebsite.com is connected to a different account")

        static let findYourConnectedEmail = NSLocalizedString("Find your connected email",
                                                     comment: "Button linking to webview explaining how to find your connected email"
                                                        + "Presented when logging in with a store address that does not match the account entered")

        static let logOutButtonTitle = NSLocalizedString("Log Out",
                                                          comment: "Action button triggering a Log Out."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let secondaryButtonTitle = NSLocalizedString("See Connected Stores",
                                                          comment: "Action button linking to a list of connected stores."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let primaryButtonTitle = NSLocalizedString("Connect Jetpack",
                                                          comment: "Action button to handle Jetpack connection."
                                                          + "Presented when logging in with a self-hosted site that does not match the account entered")

        static let yourSite = NSLocalizedString("your site",
                                                comment: "Placeholder for site url, if the url is unknown."
                                                    + "Presented when logging in with a store address that does not match the account entered.")

        static let wrongAccountMessage = NSLocalizedString("Wrong account?",
                                                           comment: "Prompt asking users if the logged in to the wrong account."
                                                               + "Presented when logging in with a store address that does not match the account entered.")

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"
    }
}
