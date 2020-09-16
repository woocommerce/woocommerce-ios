import UIKit
import CoreServices
import Yosemite
import WordPressUI

// MARK: - UITableViewDragDelegate
//
extension ProductDownloadListViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = viewModel.item(at: indexPath.row)
        if let item = item {
            let itemProvider = NSItemProvider(object: item)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        } else {
            return []
        }
    }
}
