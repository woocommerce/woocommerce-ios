import Foundation


// MARK: - Dictionary Helper Methods
//
extension Dictionary {

    /// This method returns the [AnyHashable: Any] dictionary for a given key, if possible.
    ///
    /// - Parameter key: The key to retrieve.
    ///
    /// - Returns: Value as a [AnyHashable: Any] instance
    ///
    public func dictionary(forKey key: Key) -> [AnyHashable: Any]? {
        return self[key] as? [AnyHashable: Any]
    }


    /// This method attempts to convert a given value into a String, if it's not already the case.
    /// Initial implementation supports only NSNumber. This is meant for bulletproof parsing, in which a String
    /// value might be serialized, backend side, as a Number.
    ///
    /// - Parameter key: The key to retrieve.
    ///
    /// - Returns: Value as a String (when possible!)
    ///
    public func string(forKey key: Key) -> String? {
        switch self[key] {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.description
        default:
            return nil
        }
    }


    /// This method attempts to convert a given value into an Integer, if it's not already the case.
    ///
    /// - Parameter key: The key to retrieve.
    ///
    /// - Returns: Value as a Integer (when possible!)
    ///
    public func integer(forKey key: Key) -> Int64? {
        switch self[key] {
        case let integer as Int64:
            return integer
        case let string as String:
            return Int64(string)
        case let number as NSNumber:
            return number.int64Value
        default:
            return nil
        }
    }
}
