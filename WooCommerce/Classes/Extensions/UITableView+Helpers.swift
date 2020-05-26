import UIKit

extension UITableView {

    /// Return the last Index Path (the last row of the last section) if available
    func lastIndexPath() -> IndexPath? {
        guard numberOfSections > 0 else {
            return nil
        }
        let section = max(numberOfSections - 1, 0)
        
        guard numberOfRows(inSection: section) > 0 else {
            return nil
        }
        let row = max(numberOfRows(inSection: section) - 1, 0)
        
        return IndexPath(row: row, section: section)
    }
}
