import Foundation

/// Mapper: Store API Checkout Response
///
struct StoreAPICheckoutResponseMapper: Mapper {
    /// (Attempts) to convert response data into a StoreAPICheckoutResponse.
    ///
    func map(response: Data) throws -> StoreAPICheckoutResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(StoreAPICheckoutResponse.self, from: response)
    }
}
