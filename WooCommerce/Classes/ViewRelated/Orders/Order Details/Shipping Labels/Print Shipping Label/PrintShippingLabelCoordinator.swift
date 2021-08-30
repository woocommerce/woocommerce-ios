import UIKit
import SwiftUI
import Yosemite

/// Coordinates navigation actions for printing a shipping label.
final class PrintShippingLabelCoordinator {
    private let sourceNavigationController: UINavigationController
    private let shippingLabel: ShippingLabel
    private let stores: StoresManager
    private let analytics: Analytics
    private let printType: PrintType
    private let onCompletion: (() -> Void)?

    /// - Parameter shippingLabel: The shipping label to print.
    /// - Parameter printType: Whether the label is being printed for the first time or reprinted.
    /// - Parameter sourceNavigationController: The navigation controller that shows the print UI in the first place.
    /// - Parameter stores: Handles Yosemite store actions.
    /// - Parameter analytics: Tracks analytics events.
    init(shippingLabel: ShippingLabel,
         printType: PrintType,
         sourceNavigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: (() -> Void)? = nil) {
        self.shippingLabel = shippingLabel
        self.printType = printType
        self.sourceNavigationController = sourceNavigationController
        self.stores = stores
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    /// Shows the main screen for printing a shipping label.
    /// `self` is retained in the action callbacks so that the coordinator has the same life cycle as the main view controller
    /// (`PrintShippingLabelViewController`).
    func showPrintUI() {
        let printViewController = PrintShippingLabelViewController(shippingLabel: shippingLabel, printType: printType)

        printViewController.onAction = { actionType in
            switch actionType {
            case .showPaperSizeSelector(let paperSizeOptions, let selectedPaperSize, let onSelection):
                self.showPaperSizeSelector(paperSizeOptions: paperSizeOptions,
                                           selectedPaperSize: selectedPaperSize,
                                           onPaperSizeSelected: onSelection)
            case .print(let paperSize):
                self.printShippingLabel(paperSize: paperSize)
            case .presentPaperSizeOptions:
                self.presentPaperSizeOptions()
            case .presentPrintingInstructions:
                self.presentPrintingInstructions()
            case .saveLabelForLater:
                self.saveLabelForLater()
            }
        }

        // Since the print UI could make an API request for printing data, disables the bottom bar (tab bar) to simplify app states.
        printViewController.hidesBottomBarWhenPushed = true
        sourceNavigationController.show(printViewController, sender: sourceNavigationController)
    }
}

extension PrintShippingLabelCoordinator {
    enum PrintType {
        case print
        case reprint
    }
}

// MARK: Navigation actions
private extension PrintShippingLabelCoordinator {
    func showPaperSizeSelector(paperSizeOptions: [ShippingLabelPaperSize],
                               selectedPaperSize: ShippingLabelPaperSize?,
                               onPaperSizeSelected: @escaping (ShippingLabelPaperSize?) -> Void) {
        let command = ShippingLabelPaperSizeListSelectorCommand(paperSizeOptions: paperSizeOptions, selected: selectedPaperSize)
        let listSelector = ListSelectorViewController(command: command) { paperSize in
            onPaperSizeSelected(paperSize)
        }
        sourceNavigationController.show(listSelector, sender: sourceNavigationController)
    }

    func printShippingLabel(paperSize: ShippingLabelPaperSize) {
        presentPrintInProgressUI()
        requestDocumentForPrinting(paperSize: paperSize) { result in
            self.dismissPrintInProgressUI()
            switch result {
            case .success(let printData):
                self.presentAirPrint(printData: printData)
            case .failure(let error):
                DDLogError("Error generating shipping label document for printing: \(error)")
                self.presentErrorAlert(title: Localization.printErrorAlertTitle)
            }
        }
    }

    func presentPrintInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.inProgressTitle, message: Localization.inProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext
        sourceNavigationController.present(inProgressViewController, animated: true, completion: nil)
    }

    func dismissPrintInProgressUI() {
        sourceNavigationController.dismiss(animated: true)
    }

    func presentAirPrint(printData: ShippingLabelPrintData) {
        let printController = UIPrintInteractionController()
        printController.printingItem = printData.data
        printController.present(animated: true) { [weak self] (_, _, _) in
            self?.showCustomsFormPrintingIfNeeded()
        }
    }

    func presentPaperSizeOptions() {
        let paperSizeOptionsViewController = ShippingLabelPaperSizeOptionsViewController()
        let navigationController = WooNavigationController(rootViewController: paperSizeOptionsViewController)
        sourceNavigationController.present(navigationController, animated: true, completion: nil)
    }

    func presentPrintingInstructions() {
        let printingInstructionsViewController = ShippingLabelPrintingInstructionsViewController()
        let navigationController = WooNavigationController(rootViewController: printingInstructionsViewController)
        sourceNavigationController.present(navigationController, animated: true, completion: nil)
    }

    func saveLabelForLater() {
        onCompletion?()
    }
}

// MARK: Store actions
private extension PrintShippingLabelCoordinator {
    /// Requests document data for printing a shipping label with the selected paper size.
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
private extension PrintShippingLabelCoordinator {
    func presentErrorAlert(title: String?) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.view.tintColor = .text

        alertController.addCancelActionWithTitle(Localization.printErrorAlertDismissAction)

        sourceNavigationController.present(alertController, animated: true)
    }

    /// Show customs form printing if separate customs form is available
    ///
    func showCustomsFormPrintingIfNeeded() {
        guard let url = shippingLabel.commercialInvoiceURL,
              printType == .print else {
            return
        }
        let printCustomsFormsView = PrintCustomsFormsView(invoiceURLs: [url], showsSaveForLater: true)
        let hostingController = UIHostingController(rootView: printCustomsFormsView)
        sourceNavigationController.show(hostingController, sender: self)
    }
}

private extension PrintShippingLabelCoordinator {
    enum Localization {
        static let inProgressTitle = NSLocalizedString("Printing Label",
                                                       comment: "Title of in-progress modal when requesting shipping label document for printing")
        static let inProgressMessage = NSLocalizedString("Please wait",
                                                         comment: "Message of in-progress modal when requesting shipping label document for printing")
        static let printErrorAlertTitle = NSLocalizedString("Error previewing shipping label",
                                                         comment: "Alert title when there is an error requesting shipping label document for printing")
        static let printErrorAlertDismissAction = NSLocalizedString(
            "OK",
            comment: "Dismiss button on the alert when there is an error requesting shipping label document for printing")
    }
}
