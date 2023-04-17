import Foundation


/// Mapper: OrderNote (Singular)
///
struct OrderNoteMapper: Mapper {

    let siteID: Int64

    /// (Attempts) to convert a dictionary into a single OrderNote
    ///
    func map(response: Data) throws -> OrderNote {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        guard siteID != WooConstants.placeholderSiteID else {
            return try decoder.decode(OrderNote.self, from: response)
        }
        return try decoder.decode(OrderNoteEnvelope.self, from: response).orderNote
    }
}


/// OrderNote Disposable Entity:
/// `Add Order Note` endpoint the single added note within the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct OrderNoteEnvelope: Decodable {
    let orderNote: OrderNote

    private enum CodingKeys: String, CodingKey {
        case orderNote = "data"
    }
}
