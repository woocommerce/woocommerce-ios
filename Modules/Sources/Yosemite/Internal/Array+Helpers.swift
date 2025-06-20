import Foundation


public extension Array where Element: Hashable {

    /// Non-mutated function that removes duplicates in an array.
    ///
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
