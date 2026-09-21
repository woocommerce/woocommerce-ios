import Foundation

public extension ProductType {

    /// Whether this product type represents a bookable product, of either the current `bookable-service`
    /// type or the older `booking` one. Both are labelled "Bookable" to a merchant.
    var isBookable: Bool {
        self == .booking || self == .legacyBooking
    }
}
