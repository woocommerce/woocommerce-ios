import Foundation

/// Mapper: Store API Cart
///
struct StoreAPICartMapper: Mapper {
    /// (Attempts) to convert response data into a StoreAPICart.
    ///
    func map(response: Data) throws -> StoreAPICart {
        let decoder = JSONDecoder()
        return try decoder.decode(StoreAPICart.self, from: response)
    }
}
