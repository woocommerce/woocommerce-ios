import Foundation
import WordPressUI

/// We are going to need to write a new modal view to present user facing messages related to payments.
/// https://github.com/woocommerce/woocommerce-ios/issues/3980
/// In the meantime, this, based on FancyAlertViewController, will have to do
public extension FancyAlertViewController {

    static func makeCollectPaymentAlert(name: String, amount: String, image: UIImage) -> FancyAlertViewController {

        let config = configuration(title: name, bodyText: amount, image: image)

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }

    static func configuration(title: String, bodyText: String, image: UIImage) -> FancyAlertViewController.Config {
        FancyAlertViewController.Config(titleText: title,
                                        bodyText: bodyText,
                                        headerImage: image,
                                        dividerPosition: .top,
                                        defaultButton: nil,
                                        cancelButton: nil,
                                        moreInfoButton: nil,
                                        dismissAction: {})
    }

    static func configurationForSuccess(title: String, bodyText: String, image: UIImage,
                                        printAction: @escaping () -> Void,
                                        emailAction: @escaping () -> Void) -> FancyAlertViewController.Config {
        FancyAlertViewController.Config(titleText: title,
                                        bodyText: bodyText,
                                        headerImage: image,
                                        dividerPosition: .top,
                                        defaultButton: makePrintButon(printAction: printAction),
                                        cancelButton: makeEmailButton(emailAction: emailAction),
                                        moreInfoButton: makeNoThanksButton(),
                                        dismissAction: {})
    }

    private static func makePrintButon(printAction: @escaping () -> Void) -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.printReceipt) { controller, _ in
            printAction()
            controller.dismiss(animated: true)
        }
    }

    private static func makeEmailButton(emailAction: @escaping () -> Void) -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.emailReceipt) { controller, _ in
            emailAction()
            controller.dismiss(animated: true)
        }
    }

    private static func makeNoThanksButton() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.noThanks) { controller, _ in
            controller.dismiss(animated: true)
        }
    }
}


private extension FancyAlertViewController {
    enum Localization {
        static let printReceipt = NSLocalizedString(
            "Print receipt",
            comment: "Button to print receipts. Presented to users after a payment has been successfully collected"
        )

        static let emailReceipt = NSLocalizedString(
            "Email receipt",
            comment: "Button to email receipts. Presented to users after a payment has been successfully collected"
        )

        static let noThanks = NSLocalizedString(
            "No thanks",
            comment: "Button to dismiss modal overlay. Presented to users after a payment has been successfully collected"
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
