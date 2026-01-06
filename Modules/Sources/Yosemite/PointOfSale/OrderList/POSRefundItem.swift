import Foundation

public struct POSRefundItem: Equatable, Hashable {
    public let productID: Int64
    public let variationID: Int64
    public let quantity: Decimal

    public var productOrVariationID: Int64 {
        variationID == 0 ? productID : variationID
    }
}
