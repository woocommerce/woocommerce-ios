import WordPressUI
import SafariServices

public extension FancyAlertViewController {
    static func makeWhatIsJetpackAlertController() -> FancyAlertViewController {
        let dismissButton = makeDismissButtonConfig()
        let moreInfoButton = makeMoreInfoButtonConfig()
        let config = FancyAlertViewController.Config(titleText: Localization.whatIsJetpack,
                                                     bodyText: Localization.whatIsJetpackLongDescription,
                                                     headerImage: .whatIsJetpackImage,
                                                     dividerPosition: .top,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: moreInfoButton,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    static func makeNeedHelpFindingEmailAlertController() -> FancyAlertViewController {
        let dismissButton = makeDismissButtonConfig()
        let moreHelpButton = makeNeedMoreHelpButton()
        let config = FancyAlertViewController.Config(titleText: Localization.whatEmailDoIUse,
                                                     bodyText: Localization.whatEmailDoIUseLongDescription,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: moreHelpButton,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller

    }
}


private extension FancyAlertViewController {
    enum Localization {
        static let whatIsJetpack = NSLocalizedString(
            "What is Jetpack?",
            comment: "Title of alert informing users of what Jetpack is. Presented when users attempt to log in without Jetpack installed or connected"
        )

        static let whatIsJetpackLongDescription = NSLocalizedString(
            "Jetpack is a free WordPress plugin that connects your store with tools needed to give you the best mobile experience, "
            + "including push notifications and stats.",
            comment: "Long description of what Jetpack is. Presented when users attempt to log in without Jetpack installed or connected"
        )

        static let learnMore = NSLocalizedString(
            "Learn more about Jetpack",
            comment: "Title of button to learn more presented when users attempt to log in without Jetpack installed or connected"
        )

        static let dismissButton = NSLocalizedString(
            "Continue",
            comment: "Title of dismiss button presented when users attempt to log in without Jetpack installed or connected"
        )

        static let whatEmailDoIUse = NSLocalizedString(
            "What email do I use to sign in?",
            comment: "Title of alert informing users of what email they can use to sign in."
            + "Presented when users attempt to log in with an email that does not match a WP.com account"
        )

        static let whatEmailDoIUseLongDescription = NSLocalizedString(
            "In your site admin you can find the email you used to connect to WordPress.com from the Jetpack Dashboard under Connections > Account Connection",
            comment: "Long descriptions of alert informing users of what email they can use to sign in."
                + "Presented when users attempt to log in with an email that does not match a WP.com account"
        )

        static let needMoreHelp = NSLocalizedString(
            "Need more help?",
            comment: "Title of button to learn more presented when users attempt to log in with an email address that does not match a WP.com account"
        )
    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"

        static let whatsJetpackURLString = "https://jetpack.com/about/"
    }
}


private extension FancyAlertViewController {
    static func makeDismissButtonConfig() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.dismissButton) { controller, _ in
            controller.dismiss(animated: true)
        }
    }

    static func makeMoreInfoButtonConfig() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.learnMore) { controller, _ in
            guard let url = URL(string: Strings.whatsJetpackURLString) else {
                return
            }

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            controller.present(safariViewController, animated: true)
        }
    }

    static func makeNeedMoreHelpButton() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.needMoreHelp) { controller, _ in
            let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
            guard let supportViewController = UIStoryboard
                    .dashboard
                    .instantiateViewController(withIdentifier: identifier) as? HelpAndSupportViewController else {
                return
            }

            supportViewController.displaysDismissAction = true

            let navController = WooNavigationController(rootViewController: supportViewController)
            navController.modalPresentationStyle = .formSheet

            controller.present(navController, animated: true, completion: nil)
        }
    }
}
