import Foundation


/// Maps a JSON Document into a collection of [Order]
///
class OrderListMapper: Mapper {

    /// Defines the Output Type
    ///
    typealias Output = [Order]

    /// (Attempts) to convert a dictionary into [Order].
    ///
    func map(response: Data) throws -> [Order] {
        let list = try JSONDecoder().decode(OrdersList.self, from: response)
        return list.orders
    }
}



/// OrderList Disposable Entity:
/// `Load All Orders` endpoint returns all of it's orders within the `data` key. This entity allows us to do parse all the things with
/// JSONDecoder.
///
struct OrdersList: Decodable {
    let orders: [Order]

    private enum CodingKeys: String, CodingKey {
        case orders = "data"
    }
}
