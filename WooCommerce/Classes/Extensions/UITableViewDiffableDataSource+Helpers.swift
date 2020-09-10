import UIKit

@available(iOS 13.0, *)
extension UITableViewDiffableDataSource {
    var numberOfItems: Int {
        snapshot().numberOfItems
    }
}
