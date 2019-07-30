import Foundation

/// A wrapper of dictionary that can be updated asynchronously.
///
final class AsyncDictionary<Key, Value> where Key: Hashable {
    private var dictionary: [Key: Value] = [:]
    private var operationUUIDsByKey: [Key: UUID] = [:]

    /// Returns value for key.
    ///
    func value(forKey key: Key) -> Value? {
        return dictionary[key]
    }

    /// Calculates the value for a key asynchronously, updates the dictionary, and then calls the update callback.
    ///
    /// - Parameters:
    ///   - key: key for value
    ///   - operation: called to calculate the value for key asynchronously
    ///   - onCompletion: called on main thread after the operation finishes. If the calculated value can be updated for
    ///     key, the value is returned. Otherwise, if the calculated cannot be updated for the key (e.g. the dictionary
    ///     has been cleared or a later operation has been scheduled), nil is returned
    func calculate(forKey key: Key,
                   operation: @escaping () -> (Value),
                   onCompletion: @escaping (Value?) -> ()) {
        let uuid = UUID()
        operationUUIDsByKey[key] = uuid
        DispatchQueue.global().async {
            let value = operation()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    onCompletion(nil)
                    return
                }
                guard self.operationUUIDsByKey[key] == uuid else {
                    onCompletion(nil)
                    return
                }
                self.dictionary[key] = value
                onCompletion(value)
            }
        }
    }

    /// Removes all entries in the dictionary.
    ///
    func clear() {
        operationUUIDsByKey.removeAll()
        dictionary.removeAll()
    }
}
