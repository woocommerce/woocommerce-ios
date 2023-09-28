private typealias EntityIDDictionary = [String: Int64]

/// Mapper: Single Entity ID
///
struct EntityIDMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an into an ID
    ///
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()

        let idDictionary: EntityIDDictionary
        if hasDataEnvelope(in: response) {
            idDictionary = try decoder.decode(Envelope<EntityIDDictionary>.self, from: response).data
        } else {
            idDictionary = try decoder.decode(EntityIDDictionary.self, from: response)
        }

        return idDictionary["id"] ?? .zero
    }
}
