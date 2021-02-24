import UIKit
import Yosemite

/// Coordinates navigation actions for reprinting a shipping label.
final class ReprintShippingLabelCoordinator {
    private let sourceViewController: UIViewController
    private let shippingLabel: ShippingLabel
    private let stores: StoresManager
    private let analytics: Analytics

    /// - Parameter shippingLabel: The shipping label to reprint.
    /// - Parameter sourceViewController: The view controller that shows the reprint UI in the first place.
    /// - Parameter stores: Handles Yosemite store actions.
    /// - Parameter analytics: Tracks analytics events.
    init(shippingLabel: ShippingLabel,
         sourceViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.shippingLabel = shippingLabel
        self.sourceViewController = sourceViewController
        self.stores = stores
        self.analytics = analytics
    }

    /// Shows the main screen for reprinting a shipping label.
    /// `self` is retained in the action callbacks so that the coordinator has the same life cycle as the main view controller
    /// (`ReprintShippingLabelViewController`).
    func showReprintUI() {
        let reprintViewController = ReprintShippingLabelViewController(shippingLabel: shippingLabel)

        reprintViewController.onAction = { actionType in
            switch actionType {
            case .showPaperSizeSelector(let paperSizeOptions, let selectedPaperSize, let onSelection):
                self.showPaperSizeSelector(paperSizeOptions: paperSizeOptions,
                                           selectedPaperSize: selectedPaperSize,
                                           onPaperSizeSelected: onSelection)
            case .reprint(let paperSize):
                self.reprintShippingLabel(paperSize: paperSize)
            case .presentPaperSizeOptions:
                self.presentPaperSizeOptions()
            case .presentPrintingInstructions:
                self.presentPrintingInstructions()
            }
        }

        // Since the reprint UI could make an API request for printing data, disables the bottom bar (tab bar) to simplify app states.
        reprintViewController.hidesBottomBarWhenPushed = true
        sourceViewController.show(reprintViewController, sender: sourceViewController)
    }
}

// MARK: Navigation actions
private extension ReprintShippingLabelCoordinator {
    func showPaperSizeSelector(paperSizeOptions: [ShippingLabelPaperSize],
                               selectedPaperSize: ShippingLabelPaperSize?,
                               onPaperSizeSelected: @escaping (ShippingLabelPaperSize?) -> Void) {
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: paperSizeOptions, selected: selectedPaperSize)
        let listSelector = ListSelectorViewController(command: command) { paperSize in
            onPaperSizeSelected(paperSize)
        }
        sourceViewController.show(listSelector, sender: sourceViewController)
    }

    func reprintShippingLabel(paperSize: ShippingLabelPaperSize) {
        presentReprintInProgressUI()
        requestDocumentForPrinting(paperSize: paperSize) { result in
            self.dismissReprintInProgressUI()
            switch result {
            case .success(let printData):
                self.presentAirPrint(printData: printData)
            case .failure(let error):
                DDLogError("Error generating shipping label document for printing: \(error)")
                self.presentErrorAlert(title: Localization.reprintErrorAlertTitle)
            }
        }
    }

    func presentReprintInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.inProgressTitle, message: Localization.inProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext
        sourceViewController.present(inProgressViewController, animated: true, completion: nil)
    }

    func dismissReprintInProgressUI() {
        sourceViewController.dismiss(animated: true)
    }

    func presentAirPrint(printData: ShippingLabelPrintData) {
        let printController = UIPrintInteractionController()
        printController.printingItem = printData.data
        printController.present(animated: true, completionHandler: nil)
    }

    func presentPaperSizeOptions() {
        let paperSizeOptionsViewController = ShippingLabelPaperSizeOptionsViewController()
        let navigationController = WooNavigationController(rootViewController: paperSizeOptionsViewController)
        sourceViewController.present(navigationController, animated: true, completion: nil)
    }

    func presentPrintingInstructions() {
        let printingInstructionsViewController = ShippingLabelPrintingInstructionsViewController()
        let navigationController = WooNavigationController(rootViewController: printingInstructionsViewController)
        sourceViewController.present(navigationController, animated: true, completion: nil)
    }
}

// MARK: Store actions
private extension ReprintShippingLabelCoordinator {
    /// Requests document data for reprinting a shipping label with the selected paper size.
    func requestDocumentForPrinting(paperSize: ShippingLabelPaperSize, completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        analytics.track(.shippingLabelReprintRequested)
        let action = ShippingLabelAction.printShippingLabel(siteID: shippingLabel.siteID,
                                                            shippingLabelID: shippingLabel.shippingLabelID,
                                                            paperSize: paperSize) { result in
            completion(result)
        }
        stores.dispatch(action)
    }
}

// MARK: Private helpers
private extension ReprintShippingLabelCoordinator {
    func presentErrorAlert(title: String?) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.view.tintColor = .text

        alertController.addCancelActionWithTitle(Localization.reprintErrorAlertDismissAction)

        sourceViewController.present(alertController, animated: true)
    }
}

private extension ReprintShippingLabelCoordinator {
    enum Localization {
        static let inProgressTitle = NSLocalizedString("Printing Label",
                                                       comment: "Title of in-progress modal when requesting shipping label document for reprinting")
        static let inProgressMessage = NSLocalizedString("Please wait",
                                                         comment: "Message of in-progress modal when requesting shipping label document for reprinting")
        static let reprintErrorAlertTitle = NSLocalizedString("Error previewing shipping label",
                                                         comment: "Alert title when there is an error requesting shipping label document for reprinting")
        static let reprintErrorAlertDismissAction = NSLocalizedString(
            "OK",
            comment: "Dismiss button on the alert when there is an error requesting shipping label document for reprinting")
    }
}
