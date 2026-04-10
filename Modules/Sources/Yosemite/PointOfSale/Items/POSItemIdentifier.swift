import Foundation
import Codegen

public struct POSItemIdentifier: Hashable, Sendable, GeneratedCopiable, GeneratedFakeable {
    public let underlyingType: UnderlyingType
    public let itemID: Int64

    public init(underlyingType: UnderlyingType, itemID: Int64) {
        self.underlyingType = underlyingType
        self.itemID = itemID
    }

    public enum UnderlyingType: Sendable, GeneratedCopiable, GeneratedFakeable {
        case product
        case variation
        case coupon
        case loading
        case error
    }
}
