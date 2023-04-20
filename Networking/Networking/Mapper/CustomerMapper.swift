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
        decoder.userInfo = [.siteID: siteID]
        if response.hasDataEnvelope {
            return try decoder.decode(CustomerEnvelope.self, from: response).customer
        } else {
            return try decoder.decode(Customer.self, from: response)
        }
    }
}

private struct CustomerEnvelope: Decodable {
    let customer: Customer

    private enum CodingKeys: String, CodingKey {
        case customer = "data"
    }
}
