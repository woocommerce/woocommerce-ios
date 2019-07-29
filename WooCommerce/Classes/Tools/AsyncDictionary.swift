import Foundation

/// A wrapper of dictionary that can be updated asynchronously.
///
class AsyncDictionary<Key, Value> where Key : Hashable {
    private var dictionary: [Key: Value] = [:]

    func value(at key: Key) -> Value? {
        return dictionary[key]
    }

    func calculateAsynchronouslyAndSetValue(at key: Key,
                                            calculation: @escaping () -> (Value),
                                            onSet: @escaping (Value) -> ()) {
        DispatchQueue.global().async {
            let value = calculation()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.dictionary[key] = value
                onSet(value)
            }
        }
    }

    func clear() {
        dictionary.removeAll()
    }
}
