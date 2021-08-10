import Foundation

/// Mapper: WCPay Customer
///
struct WCPayCustomerMapper: Mapper {

    /// (Attempts) to convert a dictionary into a customer.
    ///
    func map(response: Data) throws -> WCPayCustomer {
        let decoder = JSONDecoder()

        return try decoder.decode(WCPayCustomerEnvelope.self, from: response).customer
    }
}

/// WCPayCustomerEnvelope Disposable Entity
///
/// Endpoint returns the customer in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct WCPayCustomerEnvelope: Decodable {
    let customer: WCPayCustomer

    private enum CodingKeys: String, CodingKey {
        case customer = "data"
    }
}
