import Foundation


// MARK: - Array Helpers
//
extension Array where Element == Int {

    /// Returns a sorted, de-duplicated array of integer values as a comma-separated String.
    ///
    func sortedUniqueIntToString() -> String {
        let uniqued: Array = Array(Set<Int>(self))

        let items = uniqued.sorted()
        .map { String($0) }
        .filter { !$0.isEmpty }
        .joined(separator: ",")

        return items
    }
}
