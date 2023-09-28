/// Mapper: OrderNotes
///
class OrderNotesMapper: Mapper {

    /// (Attempts) to convert a dictionary into [OrderNote].
    ///
    func map(response: Data) throws -> [OrderNote] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[OrderNote]>.self, from: response).data
        } else {
            return try decoder.decode([OrderNote].self, from: response)
        }
    }
}
