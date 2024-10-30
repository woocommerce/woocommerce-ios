import Yosemite

struct WooShippingPostPurchaseViewModel {
    /// Available paper sizes for printing the shipping label.
    let labelSizes: [ShippingLabelPaperSize] = [.label, .letter, .legal]

    /// Selected paper size for printing the shipping label.
    var selectedLabelSize: ShippingLabelPaperSize = .label
}
