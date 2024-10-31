import Yosemite
import WooFoundation

struct WooShippingPostPurchaseViewModel {
    /// Available paper sizes for printing the shipping label.
    let labelSizes: [ShippingLabelPaperSize]

    /// Selected paper size for printing the shipping label.
    var selectedLabelSize: ShippingLabelPaperSize = .label

    init(siteAddress: SiteAddress = SiteAddress()) {
        // Label sizes aren't provided by the API, so we can hard-code them to match the extension behavior:
        labelSizes = {
            var availableLabelSizes: [ShippingLabelPaperSize] = [.label, .letter]
            if [.US, .CA, .MX, .DO].contains(siteAddress.countryCode) {
                availableLabelSizes.append(.a4)
            }
            return availableLabelSizes
        }()
    }
}
