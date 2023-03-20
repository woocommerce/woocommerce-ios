import WordPressUI
import SafariServices
import WordPressAuthenticator

extension FancyAlertViewController {
    static func makeWhatIsJetpackAlertController(analytics: Analytics) -> FancyAlertViewController {
        let dismissButton = FancyAlertViewController.Config.ButtonConfig(Localization.dismissButton) { controller, _ in
            controller.dismiss(animated: true)
            analytics.track(.loginWhatIsJetpackHelpScreenOkButtonTapped)
        }
        let moreInfoButton = makeLearnMoreAboutJetpackButtonConfig(analytics: analytics)
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

    static func makeNeedHelpFindingEmailAlertController(screen: CustomHelpCenterContent.Screen? = nil) -> FancyAlertViewController {
        let dismissButton = makeDismissButtonConfig()
        let customHelpCenterContent = screen.map { CustomHelpCenterContent(screen: $0, flow: AuthenticatorAnalyticsTracker.shared.state.lastFlow) }
        let moreHelpButton = makeNeedMoreHelpButton(customHelpCenterContent: customHelpCenterContent)
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

    static func makeConnectAccountToWPComSiteAlert() -> FancyAlertViewController {
        let dismissButton = makeDismissButtonConfig()
        let config = FancyAlertViewController.Config(titleText: Localization.connectToWPComSite,
                                                     bodyText: Localization.connectToWPComSiteDescription,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    static func makeSiteCredentialLoginErrorAlert(message: String, defaultAction: (() -> Void)?) -> FancyAlertViewController {
        let moreHelpButton = makeNeedMoreHelpButton()
        let cancelButton = Config.ButtonConfig(Localization.cancelButton) { controller, _ in
            controller.dismiss(animated: true)
        }
        let webViewButton: Config.ButtonConfig? = {
            guard let defaultAction else {
                return nil
            }
            return Config.ButtonConfig(Localization.loginWithWebViewButton) { controller, _ in
                controller.dismiss(animated: true, completion: defaultAction)
            }
        }()
        let config = FancyAlertViewController.Config(titleText: nil,
                                                     bodyText: message,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: cancelButton,
                                                     cancelButton: webViewButton,
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

        static let connectToWPComSite = NSLocalizedString(
            "Connecting to a WordPress.com site",
            comment: "Title of alert for suggestion on how to connect to a WP.com site" +
            "Presented when a user logs in with an email that does not have access to a WP.com site"
        )

        static let connectToWPComSiteDescription = NSLocalizedString(
            "Please contact the site owner for an invitation to the site as a shop manager or administrator to use the app.",
            comment: "Description of alert for suggestion on how to connect to a WP.com site" +
            "Presented when a user logs in with an email that does not have access to a WP.com site"
        )

        static let cancelButton = NSLocalizedString(
            "Cancel",
            comment: "Title of dismiss button presented when site credential login fails"
        )

        static let loginWithWebViewButton = NSLocalizedString(
            "Try again with WP-Admin page",
            comment: "Title of the action button to log in with WP-Admin page in a web view, presented when site credential login fails"
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

    static func makeLearnMoreAboutJetpackButtonConfig(analytics: Analytics) -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.learnMore) { controller, _ in
            guard let url = URL(string: Strings.whatsJetpackURLString) else {
                return
            }

            WebviewHelper.launch(url, with: controller)

            analytics.track(.loginWhatIsJetpackHelpScreenLearnMoreButtonTapped)
        }
    }

    static func makeNeedMoreHelpButton(customHelpCenterContent: CustomHelpCenterContent? = nil) -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.needMoreHelp) { controller, _ in
            let identifier = HelpAndSupportViewController.classNameWithoutNamespaces
            let supportViewController = UIStoryboard.dashboard.instantiateViewController(identifier: identifier,
                                                                                         creator: { coder -> HelpAndSupportViewController? in
                guard let customHelpCenterContent = customHelpCenterContent else {
                    /// Returning nil as we don't need to customise the HelpAndSupportViewController
                    /// In this case `instantiateViewController` method will use the default `HelpAndSupportViewController` created from storyboard.
                    ///
                    return nil
                }

                return HelpAndSupportViewController(customHelpCenterContent: customHelpCenterContent, coder: coder)
            })

            supportViewController.displaysDismissAction = true

            let navController = WooNavigationController(rootViewController: supportViewController)
            navController.modalPresentationStyle = .formSheet

            controller.present(navController, animated: true, completion: nil)
        }
    }
}
