import Combine
import Foundation
import UIKit
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

final class WooShippingPostPurchaseViewModel: ObservableObject {
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let siteID: Int64
    private let labelID: Int64

    /// Available paper sizes for printing the shipping label.
    let labelSizes: [ShippingLabelPaperSize]

    let isRefundable: Bool

    /// Selected paper size for printing the shipping label.
    @Published var selectedLabelSize: ShippingLabelPaperSize = .label

    /// Tracking URL for the shipping label.
    let trackingURL: URL?

    /// Shipment pickup URL for the shipping label.
    let pickupURL: URL?

    /// Customs form URL for the shipping label
    let commercialInvoiceURL: URL?

    /// Shipping Label Account Settings ResultsController
    ///
    private lazy var accountSettingsResultsController: ResultsController<StorageShippingLabelAccountSettings> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageShippingLabelAccountSettings>(
            storageManager: storageManager,
            matching: predicate,
            fetchLimit: 1,
            sortedBy: []
        )
    }()

    init(siteID: Int64,
         labelID: Int64,
         labelSizes: [ShippingLabelPaperSize],
         isRefundable: Bool,
         trackingURL: URL?,
         pickupURL: URL?,
         commercialInvoiceURL: URL?,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.siteID = siteID
        self.labelID = labelID
        self.labelSizes = labelSizes
        self.isRefundable = isRefundable
        self.trackingURL = trackingURL
        self.pickupURL = pickupURL
        self.commercialInvoiceURL = commercialInvoiceURL
        self.stores = stores
        self.storageManager = storageManager

        configureAccountSettingsResultsController()
    }

    convenience init(shippingLabel: ShippingLabel,
                     siteAddress: SiteAddress = SiteAddress(),
                     stores: StoresManager = ServiceLocator.stores,
                     storageManager: StorageManagerType = ServiceLocator.storageManager) {
        // Label sizes aren't provided by the API, so we can hard-code them to match the extension behavior:
        // Ref: https://github.com/woocommerce/woocommerce-shipping/blob/trunk/client/components/label-purchase/label/utils.ts
        let labelSizes = {
            var availableLabelSizes: [ShippingLabelPaperSize] = [.label, .letter]
            if [.US, .CA, .MX, .DO].contains(siteAddress.countryCode) == false {
                availableLabelSizes.append(.a4)
            }
            return availableLabelSizes
        }()
        let trackingURL = ShippingLabelTrackingURLGenerator.url(for: shippingLabel)
        let pickupURL = WooShippingCarrier(rawValue: shippingLabel.carrierID)?.pickupURL
        let commercialInvoiceURL: URL? = {
            guard let urlString = shippingLabel.commercialInvoiceURL else {
                return nil
            }
            return URL(string: urlString)
        }()

        self.init(siteID: shippingLabel.siteID,
                  labelID: shippingLabel.shippingLabelID,
                  labelSizes: labelSizes,
                  isRefundable: shippingLabel.isRefundable,
                  trackingURL: trackingURL,
                  pickupURL: pickupURL,
                  commercialInvoiceURL: commercialInvoiceURL,
                  stores: stores,
                  storageManager: storageManager)
    }

    /// Fetches the shipping label in the selected paper size and presents the print dialog.
    @MainActor
    func printLabel() async throws {
        let printData = try await requestPrintData()
        presentPrintDialog(with: printData.data)
    }

    @MainActor
    func printCustomsForm(with url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        presentPrintDialog(with: data)
    }
}

private extension WooShippingPostPurchaseViewModel {
    /// Shipping Label Account Settings ResultsController monitoring
    ///
    func configureAccountSettingsResultsController() {
        accountSettingsResultsController.onDidChangeContent = { [weak self] in
            self?.updateSelectedLabelSize()
        }

        accountSettingsResultsController.onDidResetContent = { [weak self] in
            self?.updateSelectedLabelSize()
        }

        try? accountSettingsResultsController.performFetch()
        updateSelectedLabelSize()
    }

    func updateSelectedLabelSize() {
        guard let fetchedAccountSettings = accountSettingsResultsController.fetchedObjects.first else { return }
        selectedLabelSize = fetchedAccountSettings.paperSize
    }

    /// Requests the shipping label data for printing.
    @MainActor
    func requestPrintData() async throws -> ShippingLabelPrintData {
        try await withCheckedThrowingContinuation { continuation in
            let action = WooShippingAction.printLabel(siteID: siteID, labelIDs: [labelID], paperSize: selectedLabelSize) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    /// Presents the print dialog with the provided print data.
    func presentPrintDialog(with data: Data?) {
        let printController = UIPrintInteractionController()
        printController.printingItem = data
        printController.present(animated: true)
    }
}
