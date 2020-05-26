import UIKit

extension UITableView {

    /// Return the last Index Path (the last row of the last section)
    func lastIndexPath() -> IndexPath {
        let section = max(numberOfSections - 1, 0)
        let row = max(numberOfRows(inSection: section) - 1, 0)
        return IndexPath(row: row, section: section)
    }
}
