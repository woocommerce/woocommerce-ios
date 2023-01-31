import Foundation

/// Mapper: Single Entity ID
///
struct EntityIDMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an into an ID
    ///
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(EntityIDEnvelope.self, from: response).id
        } catch {
            let idDictionary = try decoder.decode(EntityIDEnvelope.EntityIDDictionaryType.self, from: response)
            return idDictionary[Constants.idKey] ?? .zero
        }
    }
}

// MARK: Constants
//
private extension EntityIDMapper {
    enum Constants {
        static let idKey = "id"
    }
}

/// Disposable Entity:
/// Allows us to parse a product ID with JSONDecoder.
///
private struct EntityIDEnvelope: Decodable {
    typealias EntityIDDictionaryType = [String: Int64]

    private let data: EntityIDDictionaryType

    // Extracts the entity ID from the underlying data
    var id: Int64 {
        data[EntityIDMapper.Constants.idKey] ?? .zero
    }

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
