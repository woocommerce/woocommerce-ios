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
}

// MARK: - Networking.Array+Woo
//
extension Array where Element == Int64 {
    /// Returns a sorted, de-duplicated array of integer values as a comma-separated String.
    ///
    func sortedUniqueIntToString() -> String {
        let uniqued: Array = Array(Set<Int64>(self))

        let items = uniqued.sorted()
        .map { String($0) }
        .filter { !$0.isEmpty }
        .joined(separator: ",")

        return items
    }
}


extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    ///
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
