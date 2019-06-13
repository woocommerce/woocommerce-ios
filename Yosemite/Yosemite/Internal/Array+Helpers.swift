import Foundation


/// Not mine. Sourced from: https://stackoverflow.com/a/46354989/4150507
///
public extension Array where Element: Hashable {

    /// Non-mutation function that removes duplicates in an array.
    ///
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
