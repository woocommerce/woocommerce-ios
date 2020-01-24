import Foundation


// MARK: - Array Helpers
//
extension Array {
    /// Removes and returns the first element in the array. If any!
    ///
    mutating func popFirst() -> Element? {
        guard isEmpty == false else {
            return nil
        }

        return removeFirst()
    }

    /// A Boolean value indicating whether the collection is not empty.
    var isNotEmpty: Bool {
        return !isEmpty
    }
}


// MARK: - Collection Helpers
//
extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    ///
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Sequence Helpers
//
extension Sequence {
    /// Get the keypaths for a elemtents in a sequence.
    ///
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }

    /// Sum a sequence of elements by keypath.
    func sum<T: Numeric>(_ keyPath: KeyPath<Element, T>) -> T {
        return map(keyPath).sum()
    }
}

extension Sequence where Element: Numeric {
    /// Returns the sum of all elements in the collection.
    func sum() -> Element { return reduce(0, +) }
}
