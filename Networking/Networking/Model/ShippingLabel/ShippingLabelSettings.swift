import Foundation

/// Represents Shipping Label Settings.
///
public struct ShippingLabelSettings: Equatable {
    public let siteID: Int64
    public let orderID: Int64

    /// The default paper size for reprinting a shipping label.
    public let paperSize: ShippingLabelPaperSize
}
