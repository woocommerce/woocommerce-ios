import Foundation

/// Mapper: ProductBookingLocation
///
struct ProductBookingLocationMapper: Mapper {
    func map(response: Data) throws -> ProductBookingLocation {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductBookingLocationEnvelope.self, from: response).data
        } else {
            return try decoder.decode(ProductBookingLocation.self, from: response)
        }
    }
}

private struct ProductBookingLocationEnvelope: Decodable {
    let data: ProductBookingLocation
}
