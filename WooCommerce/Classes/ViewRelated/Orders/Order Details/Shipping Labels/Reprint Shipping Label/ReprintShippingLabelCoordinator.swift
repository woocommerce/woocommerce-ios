import UIKit
import struct Yosemite.ShippingLabel
import struct Yosemite.ShippingLabelPrintData
import enum Yosemite.ShippingLabelPaperSize

/// Coordinates navigation for reprinting a shipping label.
protocol ReprintShippingLabelCoordinatorProtocol: class {
    /// Shows the main reprint screen given a shipping label.
    /// - Parameter shippingLabel: The shipping label to reprint.
    func showReprintUI(shippingLabel: ShippingLabel)

    /// Allows the user to select a paper size from supported options.
    /// - Parameters:
    ///   - paperSizeOptions: All paper sizes that we support for reprinting.
    ///   - selectedPaperSize: The currently selected paper size.
    ///   - onPaperSizeSelected: Called when the user leaves the paper size selector with the selected value.
    func showPaperSizeSelector(paperSizeOptions: [ShippingLabelPaperSize],
                               selectedPaperSize: ShippingLabelPaperSize?,
                               onPaperSizeSelected: @escaping (ShippingLabelPaperSize?) -> Void)

    /// Presents an in-progress modal when requesting shipping label document for reprinting.
    func presentReprintInProgressUI()

    /// Dismisses the in-progress modal when the shipping label document result is ready.
    /// When the result is successful, we present an AirPrint modal.
    /// If the result fails with an error, we present an error alert.
    /// - Parameter result: The result of shipping label document request, could be `ShippingLabelPrintData` on success or an error.
    func dismissReprintInProgressUIAndPresentPrintingResult(_ result: Result<ShippingLabelPrintData, ReprintShippingLabelError>)
}

/// Implements `ReprintShippingLabelCoordinatorProtocol` that handles all navigation actions.
final class ReprintShippingLabelCoordinator {
    private let sourceViewController: UIViewController

    /// - Parameter sourceViewController: The view controller that shows the reprint UI in the first place.
    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
    }
}

extension ReprintShippingLabelCoordinator: ReprintShippingLabelCoordinatorProtocol {
    func showReprintUI(shippingLabel: ShippingLabel) {
        let reprintViewController = ReprintShippingLabelViewController(shippingLabel: shippingLabel, coordinator: self)
        // Since the reprint UI could make an API request for printing data, disables the bottom bar (tab bar) to simplify app states.
        reprintViewController.hidesBottomBarWhenPushed = true
        sourceViewController.show(reprintViewController, sender: sourceViewController)
    }

    func showPaperSizeSelector(paperSizeOptions: [ShippingLabelPaperSize],
                               selectedPaperSize: ShippingLabelPaperSize?,
                               onPaperSizeSelected: @escaping (ShippingLabelPaperSize?) -> Void) {
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: paperSizeOptions, selected: selectedPaperSize)
        let listSelector = ListSelectorViewController(command: command) { paperSize in
            onPaperSizeSelected(paperSize)
        }
        sourceViewController.show(listSelector, sender: sourceViewController)
    }

    func presentReprintInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.inProgressTitle, message: Localization.inProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext
        sourceViewController.present(inProgressViewController, animated: true, completion: nil)
    }

    func dismissReprintInProgressUIAndPresentPrintingResult(_ result: Result<ShippingLabelPrintData, ReprintShippingLabelError>) {
        sourceViewController.dismiss(animated: true)
        switch result {
        case .success(let printData):
            let data = Data(base64Encoded: printData.base64Content)
            let printController = UIPrintInteractionController()
            printController.printingItem = data
            printController.present(animated: true, completionHandler: nil)
        case .failure(let error):
            DDLogError("Error generating shipping label document for printing: \(error)")
            switch error {
            case .noSelectedPaperSize:
                presentErrorAlert(title: Localization.reprintWithoutSelectedPaperSizeErrorAlertTitle)
            default:
                presentErrorAlert(title: Localization.reprintErrorAlertTitle)
            }
        }
    }
}

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
        static let reprintWithoutSelectedPaperSizeErrorAlertTitle =
            NSLocalizedString("Please select a paper size for printing",
                              comment: "Alert title when there is an error requesting shipping label document for reprinting")
        static let reprintErrorAlertTitle = NSLocalizedString("Error previewing shipping label",
                                                         comment: "Alert title when there is an error requesting shipping label document for reprinting")
        static let reprintErrorAlertDismissAction = NSLocalizedString(
            "OK",
            comment: "Dismiss button on the alert when there is an error requesting shipping label document for reprinting")
    }
}
