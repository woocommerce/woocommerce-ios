import Foundation

/// Represents Shipping Label Settings.
///
public struct ShippingLabelSettings: Equatable, GeneratedFakeable {
    public let siteID: Int64
    public let orderID: Int64

    /// The default paper size for reprinting a shipping label.
    public let paperSize: ShippingLabelPaperSize

    public init(siteID: Int64, orderID: Int64, paperSize: ShippingLabelPaperSize) {
        self.siteID = siteID
        self.orderID = orderID
        self.paperSize = paperSize
    }
}
