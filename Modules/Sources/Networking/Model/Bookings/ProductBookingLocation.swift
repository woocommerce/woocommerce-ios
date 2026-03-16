/// Lightweight DTO for fetching only the `booking_location` field from a Product.
///
public struct ProductBookingLocation: Decodable {
    public let productID: Int64
    public let bookingLocation: String?

    private enum CodingKeys: String, CodingKey {
        case productID = "id"
        case bookingLocation = "booking_location"
    }
}
