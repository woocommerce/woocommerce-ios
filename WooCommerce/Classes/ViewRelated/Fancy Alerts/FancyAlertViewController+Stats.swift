import WordPressUI

extension FancyAlertViewController {
    static func makeCustomRangeRedactionInformationAlert() -> FancyAlertViewController {
        let dismissButton = makeDismissButtonConfig()
        let config = FancyAlertViewController.Config(titleText: Localization.redactionInfoTitle,
                                                     bodyText: Localization.redactionInfoDescription,
                                                     headerImage: nil,
                                                     dividerPosition: .top,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}

private extension FancyAlertViewController {
    static func makeDismissButtonConfig() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Localization.dismissButton) { controller, _ in
            controller.dismiss(animated: true)
        }
    }
}

private extension FancyAlertViewController {
    enum Localization {
        static let dismissButton = NSLocalizedString(
            "fancyAlertViewControllerStats.dismissButton",
            value: "OK",
            comment: "Title of dismiss button for redaction information alert in Custom Range stats tab"
        )

        static let redactionInfoTitle = NSLocalizedString(
            "fancyAlertViewControllerStats.redactionInfoTitle",
            value: "Visitors and conversion data not available",
            comment: "Title for redaction information alert in Custom Range stats tab"
        )

        static let redactionInfoDescription = NSLocalizedString(
            "fancyAlertViewControllerStats.redactionInfoDescription",
            value: "The stats feature does not support the display of visitors and conversions data for arbitrary date ranges. "
            + "\n\nHowever, you can tap a value on the graph to see visitors and conversions for that specific range.",
            comment: "Description for redaction information alert in Custom Range stats tab"
        )
    }
}
