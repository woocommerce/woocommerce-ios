import Foundation


protocol RowIterable {
    associatedtype Row: Equatable
    var rows: [Row] { get }
}

/// Extension: [Array of Sections that conform to RowIterable]
///
extension Array where Element: RowIterable {
    func indexPathForRow(_ row: Element.Row) -> IndexPath? {
        for (sectionIndex, section) in enumerated() {
            if let rowIndex = section.rows.firstIndex(of: row) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
}
