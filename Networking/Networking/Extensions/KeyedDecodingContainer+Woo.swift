import Foundation


/// KeyedDecodingContainer Extensions
///
extension KeyedDecodingContainer {

    /// Decodes a Date entry, encoded as `a String`, for the specified Key.
    ///
    func decodeDateAsString(forKey key: K) throws -> Date {
        let dateAsString = try decode(String.self, forKey: key)

        guard let output = DateFormatter.Defaults.dateTimeFormatter.date(from: dateAsString) else {
            throw KeyedDecodingError.unknownDatetimeFormat
        }

        return output
    }

    /// Decodes a Date entry, encoded as `a String`, for the specified Key. Returns Nil if none is present.
    ///
    func decodeDateAsStringIfExists(forKey key: K) throws -> Date? {
        guard let dateAsString = try decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return DateFormatter.Defaults.dateTimeFormatter.date(from: dateAsString)
    }
}


/// Decoding Errors
///
enum KeyedDecodingError: Error {
    case unknownDatetimeFormat
}
