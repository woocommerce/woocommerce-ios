import Foundation

/// Mapper: Date Modified for an entity, Wrapped in `data` Key or not
///
struct EntityDateModifiedMapper: Mapper {

    /// (Attempts) to convert an instance of Data into a date
    ///
    func map(response: Data) throws -> Date {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        let entity: ModifiedEntity
        if hasDataEnvelope(in: response) {
            entity = try decoder.decode(Envelope<ModifiedEntity>.self, from: response).data
        } else {
            entity = try decoder.decode(ModifiedEntity.self, from: response)
        }

        return entity.dateModified
    }
}

/// Represents an entity with a date modified.
///
private struct ModifiedEntity: Decodable {
    let dateModified: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateModified = try container.decode(Date.self, forKey: .dateModified)
        self.dateModified = dateModified
    }

    enum CodingKeys: String, CodingKey {
        case dateModified = "date_modified_gmt"
    }
}
