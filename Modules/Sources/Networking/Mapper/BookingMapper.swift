import Foundation

/// Mapper: Booking
///
struct BookingMapper: Mapper {
    let siteID: Int64

    func map(response: Data) throws -> Booking {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(BookingEnvelope.self, from: response).booking
        } else {
            return try decoder.decode(Booking.self, from: response)
        }
    }
}

private struct BookingEnvelope: Decodable {
    let booking: Booking

    private enum CodingKeys: String, CodingKey {
        case booking = "data"
    }
}
