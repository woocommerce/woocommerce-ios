import Foundation

/// Defines an alternative way of decoding a type to the target type.
enum AlternativeDecodingType<T> {
    case decimal(transform: (Decimal) -> T)
    case string(transform: (String) -> T)
    case bool(transform: (Bool) -> T)
    case integer(transform: (Int) -> T)
}

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

    /// Decodes the value for a given key to a target type, where the value could one of alternative types that can be transformed to the target type.
    /// - Parameters:
    ///   - targetType: target type for a given key.
    ///   - key: the key that maps to the value to be decoded.
    ///   - shouldDecodeTargetTypeFirst: whether it should try decoding to the target type without going through the alternative types first.
    ///   - alternativeTypes: a list of alternative types that can be mapped to the target type.
    /// - Returns: optional value of the target type.
    func failsafeDecodeIfPresent<T>(targetType: T.Type,
                                    forKey key: KeyedDecodingContainer<K>.Key,
                                    shouldDecodeTargetTypeFirst: Bool = true,
                                    alternativeTypes: [AlternativeDecodingType<T>]) -> T? where T: Decodable {
        if shouldDecodeTargetTypeFirst {
            if let result = failsafeDecodeIfPresent(T.self, forKey: key) {
                return result
            }
        }

        for alternativeType in alternativeTypes {
            switch alternativeType {
            case .decimal(let transform):
                if let result = failsafeDecodeIfPresent(decimalForKey: key) {
                    return transform(result)
                }
            case .string(transform: let transform):
                if let result = failsafeDecodeIfPresent(stringForKey: key) {
                    return transform(result)
                }
            case .bool(transform: let transform):
                if let result = failsafeDecodeIfPresent(booleanForKey: key) {
                    return transform(result)
                }
            case .integer(transform: let transform):
                if let result = failsafeDecodeIfPresent(integerForKey: key) {
                    return transform(result)
                }
            }
        }
        return nil
    }

    /// Decodes a String for the specified key. Supported Encodings = [String, Integer, Double]
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

        if let stringAsDouble = failsafeDecodeIfPresent(Double.self, forKey: key) {
            return String(stringAsDouble)
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

    /// Decodes a Decimal for the specified key. Supported Encodings = [Decimal / Int / String]
    ///
    /// This method *does NOT throw*. We want this behavior so that if a malformed entity is received, we just skip it, rather
    /// than breaking the entire parsing chain.
    ///
    func failsafeDecodeIfPresent(decimalForKey key: KeyedDecodingContainer<K>.Key) -> Decimal? {
        if let decimal = failsafeDecodeIfPresent(Decimal.self, forKey: key) {
            return decimal
        }

        if let integerAsDecimal = failsafeDecodeIfPresent(Int.self, forKey: key) {
            return Decimal(integerLiteral: integerAsDecimal)
        }

        if let stringAsDecimal = failsafeDecodeIfPresent(String.self, forKey: key) {
            return Decimal(string: stringAsDecimal)
        }

        return nil
    }

    /// Decodes an array of the specified Type for a given Key (if present), discarding any malformed items in the array.
    ///
    /// **WARNING:** Only use this if it's acceptable to handle and display partial data!
    ///
    /// This method *does NOT throw*. We want this behavior so that if a malformed entity is received, we just skip it, rather
    /// than breaking the entire parsing chain.
    ///
    func failsafeDecodeIfPresent<T>(lossyList: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) -> [T] where T: Decodable {
        do {
            return try decodeIfPresent(LossyDecodableList<T>.self, forKey: key)?.elements ?? []
        } catch {
            return []
        }
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

private extension KeyedDecodingContainer {
    /// Decodable list of elements where any invalid or malformed elements are discarded/ignored.
    ///
    /// See: https://www.swiftbysundell.com/articles/ignoring-invalid-json-elements-codable/
    ///
    struct LossyDecodableList<Element>: Decodable where Element: Decodable {
        var elements: [Element]

        private struct ElementWrapper: Decodable {
            var element: Element?

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                element = try? container.decode(Element.self)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let wrappers = try container.decode([ElementWrapper].self)
            elements = wrappers.compactMap(\.element)
        }
    }
}


// MARK: - Private Decoding Constants
private enum DecodingConstants {
    static let booleanTrueAsInteger = 1
}
