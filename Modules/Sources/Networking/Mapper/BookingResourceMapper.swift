import Foundation

/// Mapper: BookingResource
///
struct BookingResourceMapper: Mapper {
    let siteID: Int64

    func map(response: Data) throws -> BookingResource {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(BookingResourceEnvelope.self, from: response).bookingResource
        } else {
            return try decoder.decode(BookingResource.self, from: response)
        }
    }
}

private struct BookingResourceEnvelope: Decodable {
    let bookingResource: BookingResource

    private enum CodingKeys: String, CodingKey {
        case bookingResource = "data"
    }
}
