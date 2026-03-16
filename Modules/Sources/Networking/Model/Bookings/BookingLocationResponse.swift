public struct BookingLocationResponse: Decodable {
    public let productID: Int64
    public let bookingLocation: String?

    private enum CodingKeys: String, CodingKey {
        case productID = "id"
        case bookingLocation = "booking_location"
    }
}
