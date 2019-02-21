import Foundation


/// Mapper: OrderStatus
///
class OrderStatusMapper: Mapper {

    /// (Attempts) to convert a dictionary into an OrderStatus entity.
    ///
    func map(response: Data) throws -> OrderStatus {
        let decoder = JSONDecoder()
        return try decoder.decode(OrderStatus.self, from: response)
    }
}
