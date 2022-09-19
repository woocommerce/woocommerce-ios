import Foundation

/// Mapper: Customer
///
struct CustomerMapper: Mapper {
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Customer endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into a `Customer` entity
    ///
    func map(response: Data) throws -> Customer {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [.siteID: siteID]
        let customer = try decoder.decode(CustomerEnvelope.self, from: response).customer
        return customer
    }
}

private struct CustomerEnvelope: Decodable {
    let customer: Customer

    private enum CodingKeys: String, CodingKey {
        case customer = "data"
    }
}
