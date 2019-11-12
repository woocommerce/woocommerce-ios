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


extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    ///
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
