import UIKit
import CoreServices
import Yosemite

// MARK: - UITableViewDragDelegate conformance
//
extension ProductDownloadListViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        if let item = viewModel.item(at: indexPath.row) {
            let itemProvider = NSItemProvider(object: item)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        } else {
            return []
        }
    }
}

// MARK: - UITableViewDropDelegate conformance
//
extension ProductDownloadListViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: ProductDownloadDragAndDrop.self)
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        var destinationIndexPath = IndexPath(row: 0, section: 0)
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else if tableView.numberOfSections > 0 {
            // Get last index path of table view.
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }

        for item in coordinator.items {
            guard let sourceIndexPathRow = item.sourceIndexPath?.row else { continue }
            item.dragItem.itemProvider.loadObject(ofClass: ProductDownloadDragAndDrop.self) { [weak self] (object, error) in
                DispatchQueue.main.async {
                    if let item = object as? ProductDownloadDragAndDrop {
                        self?.viewModel.remove(at: sourceIndexPathRow)
                        self?.viewModel.insert(item, at: destinationIndexPath.row)
                        tableView.reloadData()
                    } else {
                        return
                    }
                }
            }
        }
    }
}
