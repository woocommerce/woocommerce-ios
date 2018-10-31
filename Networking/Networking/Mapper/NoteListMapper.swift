import Foundation


/// Mapper: Notifications List
///
struct NoteListMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Note Entities.
    ///
    func map(response: Data) throws -> [Note] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(NotesEnvelope.self, from: response).notes
    }
}


/// NotesEnvelope Disposable Entity:
/// `Notifications` endpoint returns the updated order document in the `notes` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct NotesEnvelope: Decodable {
    let notes: [Note]

    private enum CodingKeys: String, CodingKey {
        case notes = "notes"
    }
}
