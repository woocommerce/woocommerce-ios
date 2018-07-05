import Foundation


/// Mapper: OrderNote
///
class OrderNoteMapper: Mapper {

    /// (Attempts) to convert a dictionary into [OrderNote].
    ///
    func map(response: Data) throws -> [OrderNote] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(OrderNoteEnvelope.self, from: response).orderNotes
    }
}


/// OrderNote Disposable Entity:
/// `Load Order Notes` endpoint returns all of its notes within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct OrderNoteEnvelope: Decodable {
    let orderNotes: [OrderNote]

    private enum CodingKeys: String, CodingKey {
        case orderNotes = "data"
    }
}
