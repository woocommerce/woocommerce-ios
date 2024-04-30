import Foundation

extension NSOrderedSet {
    func toArray<T>() -> [T] {
        guard let array = array as? [T] else {
            return []
        }
        return array
    }
}

/// Explicitly checks the type for each generic element that will be converted from NSOrderedSet to a Swift array.
/// Crash and log the error in debug builds if there's a mismatch
extension NSOrderedSet {
    func toTypeCheckedArray<T>() -> [T] {
        var typeCheckedArray = [T]()

        for element in self {
            guard let typeCheckedElement = element as? T else {
                assertionFailure("Failed conversion. \(element) is not of type \(T.self)")
                return []
            }
            typeCheckedArray.append(typeCheckedElement)
        }
        return typeCheckedArray
    }
}
