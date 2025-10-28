import Foundation

/// Used to filter bookings by product
///
public struct BookingProductFilter: Codable, Hashable {
    /// ID of the product
    /// periphery:ignore - to be used later when applying filter
    ///
    public let productID: Int64

    /// Name of the product
    ///
    public let name: String

    public init(productID: Int64, name: String) {
        self.productID = productID
        self.name = name
    }
}
