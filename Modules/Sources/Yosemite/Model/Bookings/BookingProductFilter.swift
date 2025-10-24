import Foundation

/// Used to filter bookings by product
///
public struct BookingProductFilter: Codable, Hashable {
    /// The underlying product
    public let product: Product

    /// ID of the product
    ///
    public let id: Int64

    /// Name of the product
    ///
    public let name: String

    public init(product: Product) {
        self.id = product.productID
        self.name = product.name
        self.product = product
    }
}
