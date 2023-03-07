import Foundation

/// Error when serializing an Encodable
///
public enum EncodableError: Error {

    /// Fails to convert JSONSerialization JSON object to the expected type
    ///
    case jsonSerializationType
}

extension Encodable {

    /// Attempts to serialize to a dictionary from String to Any.
    ///
    func toDictionary(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
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
}
