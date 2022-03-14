import UIKit
import AutomatticAbout
import SafariServices
import WordPressShared

final class WooAboutScreenConfiguration: AboutScreenConfiguration {
    var sections: [AboutScreenSection] {
        [
            [
                AboutItem(title: Localization.Titles.rateUs, action: { [weak self] context in
                    self?.present(url: Links.rateUs,
                                  from: context.viewController)
                }),
                AboutItem(title: Localization.Titles.share, action: { [weak self] context in
                    self?.presentShareSheet(from: context.viewController,
                                            sourceView: context.sourceView)
                }),
                AboutItem(title: Localization.Titles.instagram, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.instagram, from: context.viewController)
                }),
                AboutItem(title: Localization.Titles.twitter, subtitle: Localization.Subtitles.twitter, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.twitter, from: context.viewController)
                }),
                AboutItem(title: Localization.Titles.website, subtitle: Localization.Subtitles.website, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.website, from: context.viewController)
                }),
                AboutItem(title: Localization.Titles.blog, subtitle: Localization.Subtitles.blog, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.blog, from: context.viewController)
                })
            ],
            [
                AboutItem(title: Localization.Titles.legalAndMore, accessoryType: .disclosureIndicator, action: { context in
                    context.showSubmenu(title: Localization.Titles.legalAndMore, configuration: WooLegalAndMoreSubmenuConfiguration())
                })
            ],
            [
                AboutItem(title: Localization.Titles.automatticFamily,
                          accessoryType: .disclosureIndicator,
                          hidesSeparator: true,
                          action: { [weak self] context in
                    self?.present(url: Links.automatticFamily, from: context.viewController)
                }),
                AboutItem(title: "", cellStyle: .appLogos)
            ],
            [
                AboutItem(title: Localization.Titles.workWithUs,
                          subtitle: Localization.Subtitles.workWithUs,
                          cellStyle: .subtitle,
                          accessoryType: .disclosureIndicator,
                          action: { [weak self] context in
                              self?.present(url: Links.workWithUs, from: context.viewController)
                          })
            ]
        ]
    }

    func dismissScreen(_ actionContext: AboutItemActionContext) {
        actionContext.viewController.presentingViewController?.dismiss(animated: true)
    }

    func willShow(viewController: UIViewController) {}

    func didHide(viewController: UIViewController) {}

    // MARK: - Header Info

    // Provides app info to display in the header of the about screen.
    //
    static var appInfo: AboutScreenAppInfo {
        return AboutScreenAppInfo(name: WooConstants.appDisplayName,
                                  version: Bundle.main.detailedVersionNumber(),
                                  icon: UIImage(named: iconNameFromBundle())!)
    }
}

private extension WooAboutScreenConfiguration {

    // MARK: - Presentation Actions

    func present(url: URL, from viewController: UIViewController) {
        let vc = SFSafariViewController(url: url)
        viewController.present(vc, animated: true, completion: nil)
    }

    func presentShareSheet(from viewController: UIViewController, sourceView: UIView?) {
        let activityItems = [
            ShareAppTextActivityItemSource(message: Localization.shareSheetMessage) as Any,
            Links.website as Any
        ]

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        viewController.present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - Header Info Helper

    // Returns the name of the app's primary icon as defined in Info.plist
    //
    private static func iconNameFromBundle() -> String {
        guard let icons =
                Bundle.main.infoDictionary?[Constants.infoPlistBundleIconsKey] as? [String: Any],
              let primaryIcon = icons[Constants.infoPlistPrimaryIconKey] as? [String: Any],
              let iconFiles = primaryIcon[Constants.infoPlistIconFilesKey] as? [String] else {
                  return ""
              }

        return iconFiles.last ?? ""
    }

    // MARK: - Constants

    enum Constants {
        static let infoPlistBundleIconsKey    = "CFBundleIcons"
        static let infoPlistPrimaryIconKey    = "CFBundlePrimaryIcon"
        static let infoPlistIconFilesKey      = "CFBundleIconFiles"
    }

    private enum Links {
        static let rateUs           = AppRatingManager.Constants.defaultAppReviewURL
        static let instagram        = URL(string: "http://instagram.com/woocommerce")!
        static let twitter          = URL(string: "http://twitter.com/woocommerce")!
        static let website          = URL(string: "https://woocommerce.app/")!
        static let blog             = URL(string: "https://woocommerce.com/blog/")!
        static let automatticFamily = URL(string: "https://automattic.com")!
        static let workWithUs       = URL(string: "https://automattic.com/work-with-us")!
    }

    enum Localization {
        enum Titles {
            static let rateUs           = NSLocalizedString("Rate us", comment: "Title of button that allows the user to rate the app in the App Store")
            static let share             = NSLocalizedString("Share with Friends", comment: "Title for button allowing users to share "
                                                             + "information about the app with friends, such as via Messages")
            static let instagram        = NSLocalizedString("Instagram", comment: "Title of a button linking to the app's Instagram profile")
            static let twitter          = NSLocalizedString("Twitter", comment: "Title of a button linking to the app's Twitter profile")
            static let website          = NSLocalizedString("Website", comment: "Title of a button linking to the app's website")
            static let blog             = NSLocalizedString("Blog", comment: "Title of a button linking to the app's blog")
            static let legalAndMore     = NSLocalizedString("Legal and more", comment: "Title of a button linking to a list of legal documents "
                                                            + "like privacy policy,terms of service, etc")
            static let automatticFamily = NSLocalizedString("Automattic family", comment: "Title of a button linking to the Automattic website")
            static let workWithUs       = NSLocalizedString("Work with us", comment: "Title of a button linking to the Automattic Work With Us web page")
        }

        enum Subtitles {
            static let website          = "woocommerce.app"
            static let blog             = "woocommerce.com/blog"
            static let twitter          = "@woocommerce"
            static let workWithUs       = NSLocalizedString("Join from anywhere",
                                                            comment: "Subtitle for button displaying the Automattic Work With Us web page, "
                                                            + "indicating that Automattic employees can work from anywhere in the world")
        }

        static let shareSheetMessage = NSLocalizedString("Hey! Here is a link to download the WooCommerce app. "
                                                         + "I'm really enjoying it and thought you might too.",
                                                         comment: "Text used when sharing a link to the app with a friend.")
    }
}

// MARK: - Legal and More submenu

class WooLegalAndMoreSubmenuConfiguration: AboutScreenConfiguration {
    lazy var sections: [[AboutItem]] = {
        [
            [
                linkItem(title: Localization.Titles.termsOfService, url: Links.termsOfService),
                linkItem(title: Localization.Titles.privacyPolicy, url: Links.privacyPolicy),
                linkItem(title: Localization.Titles.ccpa, url: Links.ccpa),
                AboutItem(title: Localization.Titles.openSourceLicenses, action: { [weak self] context in
                    self?.presentLicenses(from: context.viewController)
                })
            ]
        ]
    }()

    func dismissScreen(_ actionContext: AboutItemActionContext) {
        actionContext.viewController.presentingViewController?.dismiss(animated: true)
    }

    func willShow(viewController: UIViewController) {}

    func didHide(viewController: UIViewController) {}
}

private extension WooLegalAndMoreSubmenuConfiguration {

    // MARK: - Presentation Helpers

    func linkItem(title: String, url: URL) -> AboutItem {
        AboutItem(title: title, action: { [weak self] context in
            self?.present(url: url, from: context.viewController)
        })
    }

    func present(url: URL, from viewController: UIViewController) {
        let vc = SFSafariViewController(url: url)
        viewController.present(vc, animated: true, completion: nil)
    }

    func presentLicenses(from viewController: UIViewController) {
        ServiceLocator.analytics.track(.settingsLicensesLinkTapped)
        guard let licensesViewController = UIStoryboard.dashboard.instantiateViewController(ofClass: LicensesViewController.self) else {
            fatalError("Cannot instantiate `LicensesViewController` from Dashboard storyboard")
        }

        viewController.show(licensesViewController, sender: self)
    }

    // MARK: - Constants

    private enum Links {
        static let termsOfService     = WooConstants.URLs.termsOfService.asURL()
        static let privacyPolicy      = WooConstants.URLs.privacy.asURL()
        static let ccpa               = WooConstants.URLs.californiaPrivacy.asURL()
    }

    enum Localization {
        enum Titles {
            static let termsOfService     = NSLocalizedString("Terms of Service", comment: "Title of button that displays the App's terms of service")
            static let privacyPolicy      = NSLocalizedString("Privacy Policy", comment: "Title of button that displays the App's privacy policy")
            static let ccpa               = NSLocalizedString("Privacy Notice for California Users",
                                                              comment: "Title of button that displays the California Privacy Notice")
            static let openSourceLicenses = NSLocalizedString("Third Party Licenses", comment: "Title of button that displays information about "
                                                              + "the third party software libraries used in the creation of this app")
        }
    }
}
