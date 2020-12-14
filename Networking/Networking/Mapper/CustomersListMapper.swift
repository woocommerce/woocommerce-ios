import Foundation


/// Mapper: Customers List
///
struct CustomersListMapper: Mapper {

    /// Site Identifier associated to the API information that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [Customer].
    ///
    func map(response: Data) throws -> [Customer] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(CustomersListEnvelope.self, from: response).customers
    }
}


/// CustomersListEnvelope Disposable Entity:
/// `Load All Customers` endpoint returns the customers document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct CustomersListEnvelope: Decodable {
    let customers: [Customer]

    private enum CodingKeys: String, CodingKey {
        case customers = "data"
    }
}
