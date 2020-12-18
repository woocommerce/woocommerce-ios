import Foundation


/// Mapper: Customer
///
struct CustomerMapper: Mapper {

    /// Site Identifier associated to the refund that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Customer Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into a single Customer.
    ///
    func map(response: Data) throws -> Customer {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(CustomerEnvelope.self, from: response).customer
    }
}


/// CustomerEnvelope Disposable Entity:
/// `Create Customer` endpoint returns the created customer document in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct CustomerEnvelope: Decodable {
    let customer: Customer

    private enum CodingKeys: String, CodingKey {
        case customer = "data"
    }
}
