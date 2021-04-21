import Foundation
import WordPressUI

public extension FancyAlertViewController {

    /// Create the fancy alert controller for the WC 3.5 upgrade alert that appears after the login flow is completed.
    ///
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makeCollectPaymentAlert() -> FancyAlertViewController {

        //let dismissButton = makeDismissButtonConfig()
        //let moreInfoButton = makeMoreInfoButtonConfig()
        let config = FancyAlertViewController.Config(titleText: "Collect payment from ",
                                                     bodyText: "210",
                                                     headerImage: .cardPresentImage,
                                                     dividerPosition: .bottom,
                                                     defaultButton: nil,
                                                     cancelButton: nil,
                                                     moreInfoButton: nil,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}
