import Foundation
import Yosemite

/// Configuration and actions for an ULErrorViewController, modelling
/// an error when the user tries to log in to the app with a simple WP.com site.
struct NonAtomicSiteViewModel: ULErrorViewModel {
    private let site: Site
    private let stores: StoresManager

    var title: String? { site.name }

    let image: UIImage = .loginNoWordPressError
    
    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: site.url.trimHTTPScheme(),
                                                 attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }
    
    let isAuxiliaryButtonHidden = true
    let auxiliaryButtonTitle = ""

    let isPrimaryButtonHidden = true
    let primaryButtonTitle = ""
    
    let secondaryButtonTitle = Localization.secondaryButtonTitle

    init(site: Site, stores: StoresManager = ServiceLocator.stores) {
        self.site = site
        self.stores = stores
    }
    
    func viewDidLoad(_ viewController: UIViewController?) {
        // no-op
    }
    
    func didTapPrimaryButton(in viewController: UIViewController?) {
        // no-op
    }
    
    func didTapSecondaryButton(in viewController: UIViewController?) {
        stores.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }
    
    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        // no-op
    }
}

private extension NonAtomicSiteViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString(
            "It seems that your site %@ is a simple WordPress.com site that cannot install plugins. Please upgrade your plan to use WooCommerce.",
            comment: "An error message displayed when the user tries to log in to the app with a simple WP.com site. " +
            "Reads like: It seems that your site google.com is a simple WordPress.com site that cannot install plugins. Please upgrade your plan to use WooCommerce."
        )

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when the user tries to log in to the app with a simple WP.com site.")
    }
}
