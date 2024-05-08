#if os(iOS)

import Foundation
import Codegen

/// Represents Shipping Label Settings for an order.
///
public struct ShippingLabelSettings: Equatable, GeneratedFakeable {
    public let siteID: Int64
    public let orderID: Int64

    /// The default paper size for printing a shipping label.
    public let paperSize: ShippingLabelPaperSize

    public init(siteID: Int64, orderID: Int64, paperSize: ShippingLabelPaperSize) {
        self.siteID = siteID
        self.orderID = orderID
        self.paperSize = paperSize
    }
}

#endif
