import Foundation

/// A wrapper of dictionary that can be updated asynchronously.
///
class AsyncDictionary<Key, Value> where Key : Hashable {
    private var dictionary: [Key: Value] = [:]

    /// Returns value for key.
    ///
    func value(forKey key: Key) -> Value? {
        return dictionary[key]
    }

    /// Calculates the value for a key asynchronously, updates the dictionary, and then calls the update callback.
    ///
    /// - Parameters:
    ///   - key: key for value
    ///   - calculation: called to calculate the value for key asynchronously
    ///   - onUpdate: called on main thread after the calculated value is updated for key
    func calculateAsynchronouslyAndUpdateValue(forKey key: Key,
                                               calculation: @escaping () -> (Value),
                                               onUpdate: @escaping (Value) -> ()) {
        DispatchQueue.global().async {
            let value = calculation()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.dictionary[key] = value
                onUpdate(value)
            }
        }
    }

    /// Removes all entries in the dictionary.
    ///
    func clear() {
        dictionary.removeAll()
    }
}
