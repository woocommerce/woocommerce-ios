import Yosemite
import WooFoundation

final class WooShippingPostPurchaseViewModel: ObservableObject {
    /// Available paper sizes for printing the shipping label.
    let labelSizes: [ShippingLabelPaperSize]

    /// Selected paper size for printing the shipping label.
    @Published var selectedLabelSize: ShippingLabelPaperSize = .label

    /// Tracking URL for the shipping label.
    let trackingURL: URL?

    /// Shipment pickup URL for the shipping label.
    let pickupURL: URL?

    init(labelSizes: [ShippingLabelPaperSize],
         trackingURL: URL?,
         pickupURL: URL?) {
        self.labelSizes = labelSizes
        self.trackingURL = trackingURL
        self.pickupURL = pickupURL
    }

    convenience init(shippingLabel: ShippingLabel,
                     siteAddress: SiteAddress = SiteAddress()) {
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

        self.init(labelSizes: labelSizes,
                  trackingURL: trackingURL,
                  pickupURL: pickupURL)
    }
}
