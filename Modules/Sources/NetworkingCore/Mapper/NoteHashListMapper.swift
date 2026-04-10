import Foundation


/// Mapper: NoteHashes Collection
///
struct NoteHashListMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of NoteHash Entities.
    ///
    func map(response: Data) throws -> [NoteHash] {
        return try JSONDecoder().decode(NoteHashesEnvelope.self, from: response).hashes
    }
}


/// NoteHashesEnvelope Disposable Entity:
/// This entity allows us to parse [NoteHash] with JSONDecoder.
///
private struct NoteHashesEnvelope: Decodable {
    let hashes: [NoteHash]

    private enum CodingKeys: String, CodingKey {
        case hashes = "notes"
    }
}
