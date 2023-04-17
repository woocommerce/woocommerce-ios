import Foundation


/// Mapper: OrderNotes
///
struct OrderNotesMapper: Mapper {

    let siteID: Int64

    /// (Attempts) to convert a dictionary into [OrderNote].
    ///
    func map(response: Data) throws -> [OrderNote] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        guard siteID != WooConstants.placeholderSiteID else {
            return try decoder.decode([OrderNote].self, from: response)
        }
        return try decoder.decode(OrderNotesEnvelope.self, from: response).orderNotes
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
