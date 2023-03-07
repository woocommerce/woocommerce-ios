import Foundation


/// Mapper: OrderNotes
///
class OrderNotesMapper: Mapper {

    /// (Attempts) to convert a dictionary into [OrderNote].
    ///
    func map(response: Data) throws -> [OrderNote] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        do {
            return try decoder.decode(OrderNotesEnvelope.self, from: response).orderNotes
        } catch {
            return try decoder.decode([OrderNote].self, from: response)
        }
    }
}


/// OrderNote Disposable Entity:
/// `Load Order Notes` endpoint returns all of its notes within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderNotesEnvelope: Decodable {
    let orderNotes: [OrderNote]

    private enum CodingKeys: String, CodingKey {
        case orderNotes = "data"
    }
}
