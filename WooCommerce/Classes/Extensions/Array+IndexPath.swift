import Foundation


protocol RowIterable {
    associatedtype Row: Equatable
    var rows: [Row] { get }
}

/// Extension: [Array of Sections that conform to RowIterable]
///
extension Array where Element: RowIterable {
    func getIndexPathForRow(_ row: Element.Row) -> IndexPath? {
        for s in 0 ..< count {
            let rows = self[s].rows
            for r in 0 ..< rows.count {
                if rows[r] == row {
                    return IndexPath(row: r, section: s)
                }
            }
        }
        return nil
    }
}
