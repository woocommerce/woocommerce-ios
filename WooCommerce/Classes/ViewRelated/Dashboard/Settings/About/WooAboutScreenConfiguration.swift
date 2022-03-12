import UIKit
import AutomatticAbout
import SafariServices

class WooAboutScreenConfiguration: AboutScreenConfiguration {
    var sections: [AboutScreenSection] {
        [
            [
                AboutItem(title: Titles.rateUs, action: { [weak self] context in
                    self?.present(url: Links.rateUs,
                                  from: context.viewController)
                }),
                AboutItem(title: Titles.share, action: { [weak self] context in
                    self?.presentShareSheet(from: context.viewController,
                                            sourceView: context.sourceView)
                }),
                AboutItem(title: Titles.instagram, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.instagram, from: context.viewController)
                }),
                AboutItem(title: Titles.twitter, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.twitter, from: context.viewController)
                }),
                AboutItem(title: Titles.website, subtitle: Subtitles.website, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.website, from: context.viewController)
                }),
                AboutItem(title: Titles.blog, subtitle: Subtitles.blog, cellStyle: .value1, action: { [weak self] context in
                    self?.present(url: Links.blog, from: context.viewController)
                })
            ],
            [
                AboutItem(title: Titles.legalAndMore, accessoryType: .disclosureIndicator, action: { context in
                    context.showSubmenu(title: Titles.legalAndMore, configuration: WooLegalAndMoreSubmenuConfiguration())
                })
            ],
            [
                AboutItem(title: Titles.automatticFamily, accessoryType: .disclosureIndicator, hidesSeparator: true, action: { [weak self] context in
                    self?.present(url: Links.automatticFamily, from: context.viewController)
                }),
                AboutItem(title: "", cellStyle: .appLogos)
            ],
            [
                AboutItem(title: Titles.workWithUs,
                          subtitle: Subtitles.workWithUs,
                          cellStyle: .subtitle,
                          accessoryType: .disclosureIndicator,
                          action: { [weak self] context in
                              self?.present(url: Links.workWithUs, from: context.viewController)
                          })
            ]
        ]
    }

// MARK: - Presentation Actions

    private func present(url: URL, from viewController: UIViewController) {
        let vc = SFSafariViewController(url: url)
        viewController.present(vc, animated: true, completion: nil)
    }

    private func presentShareSheet(from viewController: UIViewController, sourceView: UIView?) {
        let activityItems = [
            ShareAppTextActivityItemSource(message: TextContent.shareSheetMessage) as Any,
            Links.website as Any
        ]

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        viewController.present(activityViewController, animated: true, completion: nil)
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
        let name = WooConstants.appDisplayName
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
        let versionString = NSLocalizedString("Version %@", comment: "The app's version. %@ will be replaced by the current version number")

        return AboutScreenAppInfo(name: name,
                                  version: String(format: versionString, version),
                                  icon: UIImage(named: iconNameFromBundle())!)
    }

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

    private enum Constants {
        static let infoPlistBundleIconsKey    = "CFBundleIcons"
        static let infoPlistPrimaryIconKey    = "CFBundlePrimaryIcon"
        static let infoPlistIconFilesKey      = "CFBundleIconFiles"
    }

    private enum Titles {
        static let rateUs           = NSLocalizedString("Rate us", comment: "Title of button that allows the user to rate the app in the App Store")
        static let share              = NSLocalizedString("Share with Friends", comment: "Title for button allowing users to share "
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

    private enum Subtitles {
        static let website          = "woocommerce.app"
        static let blog             = "woocommerce.com/blog"
        static let workWithUs       = NSLocalizedString("Join from anywhere",
                                                        comment: "Subtitle for button displaying the Automattic Work With Us web page, "
                                                                 + "indicating that Automattic employees can work from anywhere in the world")
    }

    private enum TextContent {
        static let shareSheetMessage = NSLocalizedString("Hey! Here is a link to download the WooCommerce app. "
                                                         + "I'm really enjoying it and thought you might too.",
                                                         comment: "Text used when sharing a link to the app with a friend.")
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
}

// MARK: - Legal and More submenu

class WooLegalAndMoreSubmenuConfiguration: AboutScreenConfiguration {
    lazy var sections: [[AboutItem]] = {
        [
            [
                linkItem(title: Titles.termsOfService, url: Links.termsOfService),
                linkItem(title: Titles.privacyPolicy, url: Links.privacyPolicy),
                linkItem(title: Titles.ccpa, url: Links.ccpa),
                AboutItem(title: Titles.openSourceLicenses, action: { [weak self] context in
                    self?.presentLicenses(from: context.viewController)
                })
            ]
        ]
    }()

    private func linkItem(title: String, url: URL) -> AboutItem {
        AboutItem(title: title, action: { [weak self] context in
            self?.present(url: url, from: context.viewController)
        })
    }

    private func present(url: URL, from viewController: UIViewController) {
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


    func dismissScreen(_ actionContext: AboutItemActionContext) {
        actionContext.viewController.presentingViewController?.dismiss(animated: true)
    }

    func willShow(viewController: UIViewController) {}

    func didHide(viewController: UIViewController) {}

    private enum Titles {
        static let termsOfService     = NSLocalizedString("Terms of Service", comment: "Title of button that displays the App's terms of service")
        static let privacyPolicy      = NSLocalizedString("Privacy Policy", comment: "Title of button that displays the App's privacy policy")
        static let ccpa               = NSLocalizedString("Privacy Notice for California Users",
                                                          comment: "Title of button that displays the California Privacy Notice")
        static let openSourceLicenses = NSLocalizedString("Third Party Licenses", comment: "Title of button that displays information about "
                                                          + "the third party software libraries used in the creation of this app")
    }

    private enum Links {
        static let termsOfService     = WooConstants.URLs.termsOfService.asURL()
        static let privacyPolicy      = WooConstants.URLs.privacy.asURL()
        static let ccpa               = WooConstants.URLs.californiaPrivacy.asURL()
    }
}
