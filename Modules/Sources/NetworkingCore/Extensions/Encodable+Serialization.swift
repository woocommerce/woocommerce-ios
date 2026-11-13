import Foundation

/// Error when serializing an Encodable
///
public enum EncodableError: Error {

    /// Fails to convert JSONSerialization JSON object to the expected type
    ///
    case jsonSerializationType
}

public extension Encodable {

    /// Attempts to serialize to a JSON object dictionary from String to Any.
    ///
    func toJSONObjectDictionary(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                                dateFormatter: DateFormatter = DateFormatter.Defaults.dateTimeFormatter) throws -> [String: Any] {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
        jsonEncoder.keyEncodingStrategy = keyEncodingStrategy

        let data = try jsonEncoder.encode(self)

        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw EncodableError.jsonSerializationType
            }
            return dictionary
        } catch {
            throw error
        }
    }

    /// Attempts to serialize to request parameters.
    ///
    func toDictionary(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                      dateFormatter: DateFormatter = DateFormatter.Defaults.dateTimeFormatter) throws -> RequestParameterDictionary {
        try toJSONObjectDictionary(keyEncodingStrategy: keyEncodingStrategy, dateFormatter: dateFormatter).requestParameterDictionaryFromJSONObject()
    }
}
