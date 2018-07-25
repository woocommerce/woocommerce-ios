import Foundation


/// Mapper: OrderNote (Singular)
///
class OrderNoteMapper: Mapper {

    /// (Attempts) to convert a dictionary into a single OrderNote
    ///
    func map(response: Data) throws -> OrderNote {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        let decoded = try decoder.decode(OrderNote.self, from: response)
        return decoded
    }
}
