import Yosemite
import WooFoundation

final class WooShippingPostPurchaseViewModel: ObservableObject {
    private let stores: StoresManager
    private let siteID: Int64
    private let labelID: Int64

    /// Available paper sizes for printing the shipping label.
    let labelSizes: [ShippingLabelPaperSize]

    /// Selected paper size for printing the shipping label.
    @Published var selectedLabelSize: ShippingLabelPaperSize = .label

    /// Tracking URL for the shipping label.
    let trackingURL: URL?

    /// Shipment pickup URL for the shipping label.
    let pickupURL: URL?

    init(siteID: Int64,
         labelID: Int64,
         labelSizes: [ShippingLabelPaperSize],
         trackingURL: URL?,
         pickupURL: URL?,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.labelID = labelID
        self.labelSizes = labelSizes
        self.trackingURL = trackingURL
        self.pickupURL = pickupURL
        self.stores = stores
    }

    convenience init(shippingLabel: ShippingLabel,
                     siteAddress: SiteAddress = SiteAddress(),
                     stores: StoresManager = ServiceLocator.stores) {
        // Label sizes aren't provided by the API, so we can hard-code them to match the extension behavior:
        let labelSizes = {
            var availableLabelSizes: [ShippingLabelPaperSize] = [.label, .letter]
            if [.US, .CA, .MX, .DO].contains(siteAddress.countryCode) {
                availableLabelSizes.append(.a4)
            }
            return availableLabelSizes
        }()
        let trackingURL = ShippingLabelTrackingURLGenerator.url(for: shippingLabel)
        let pickupURL = WooShippingCarrier(rawValue: shippingLabel.carrierID)?.pickupURL

        self.init(siteID: shippingLabel.siteID,
                  labelID: shippingLabel.shippingLabelID,
                  labelSizes: labelSizes,
                  trackingURL: trackingURL,
                  pickupURL: pickupURL,
                  stores: stores)
    }

    /// Fetches the shipping label in the selected paper size and presents the print dialog.
    @MainActor
    func printLabel() async {
        do {
            let printData = try await requestPrintData()
            // TODO: Present the print dialog
        } catch {
            DDLogError("Error generating shipping label document for printing: \(error)")
        }
    }
}

private extension WooShippingPostPurchaseViewModel {
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
}
