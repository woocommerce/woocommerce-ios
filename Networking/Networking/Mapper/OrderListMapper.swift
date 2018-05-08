import Foundation


/// Mapper: OrderList
///
class OrderListMapper: Mapper {

    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> [Order] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(OrdersList.self, from: response).orders
    }
}



/// OrderList Disposable Entity:
/// `Load All Orders` endpoint returns all of it's orders within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
struct OrdersList: Decodable {
    let orders: [Order]

    private enum CodingKeys: String, CodingKey {
        case orders = "data"
    }
}
