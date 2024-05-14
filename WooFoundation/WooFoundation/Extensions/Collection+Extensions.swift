import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    ///
    public subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    /// A Boolean value indicating whether a collection is not empty.
    public var isNotEmpty: Bool {
        !isEmpty
    }

    /// A Bool indicating if the collection has at least two elements
    public var containsMoreThanOne: Bool {
        count > 1
    }
}
