import Foundation


// MARK: - KeyedDecodingContainer: Bulletproof JSON Decoding.
//
extension KeyedDecodingContainer {

    /// Decodes the specified Type for a given Key (if present).
    ///
    /// This method *does NOT throw*. We want this behavior so that if a malformed entity is received, we just skip it, rather
    /// than breaking the entire parsing chain.
    ///
    func failsafeDecodeIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) -> T? where T: Decodable {
        do {
            return try decodeIfPresent(type, forKey: key)
        } catch {
            return nil
        }
    }

    /// Decodes a String for the specified key. Supported Encodings = [String, Integer]
    ///
    /// This method *does NOT throw*. We want this behavior so that if a malformed entity is received, we just skip it, rather
    /// than breaking the entire parsing chain.
    ///
    func failsafeDecodeIfPresent(stringForKey key: KeyedDecodingContainer<K>.Key) -> String? {
        if let string = failsafeDecodeIfPresent(String.self, forKey: key) {
            return string
        }

        if let stringAsInteger = failsafeDecodeIfPresent(Int.self, forKey: key) {
            return String(stringAsInteger)
        }

        return nil
    }

    /// Decodes an Integer for the specified key. Supported Encodings = [Integer / String]
    ///
    /// This method *does NOT throw*. We want this behavior so that if a malformed entity is received, we just skip it, rather
    /// than breaking the entire parsing chain.
    ///
    func failsafeDecodeIfPresent(integerForKey key: KeyedDecodingContainer<K>.Key) -> Int? {
        if let integer = failsafeDecodeIfPresent(Int.self, forKey: key) {
            return integer
        }

        if let integerAsString = failsafeDecodeIfPresent(String.self, forKey: key) {
            return Int(integerAsString)
        }

        return nil
    }

    /// Decodes a Boolean for the specified key. Supported Encodings = [Bool / String]
    ///
    /// This method *does NOT throw*. We want this behavior so that if a malformed entity is received, we just skip it, rather
    /// than breaking the entire parsing chain.
    ///
    func failsafeDecodeIfPresent(booleanForKey key: KeyedDecodingContainer<K>.Key) -> Bool? {
        if let bool = failsafeDecodeIfPresent(Bool.self, forKey: key) {
            return bool
        }

        if let boolAsInteger = failsafeDecodeIfPresent(Int.self, forKey: key) {
            return boolAsInteger == DecodingConstants.booleanTrueAsInteger
        }

        return nil
    }
}


// MARK: - Convenience Decoding Methods
//
extension KeyedDecodingContainer {

    /// Decodes a NSRange entity encoded as an array of integers, under the specified key.
    ///
    func decode(arrayEncodedRangeForKey key: KeyedDecodingContainer<K>.Key) throws -> NSRange {
        let indices = try decode([Int].self, forKey: key)
        guard let start = indices.first, let end = indices.last, indices.count == 2 else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Invalid Indices")
        }

        return NSRange(location: start, length: end - start)
    }
}


// MARK: - Private Decoding Constants
private enum DecodingConstants {
    static let booleanTrueAsInteger = 1
}
