import UIKit
import CoreServices
import Yosemite

// MARK: - UITableViewDropDelegate
//
extension ProductDownloadListViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: ProductDownloadDnD.self) || session.hasItemsConforming(toTypeIdentifiers: [kUTTypeUTF8PlainText as String])
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        let operation: UIDropOperation
        if session.items.count > 1 {
            operation = .cancel
        } else {
            operation = .move
        }
        return UITableViewDropProposal(operation: operation, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }

        for item in coordinator.items {
            guard let sourceIndexPathRow = item.sourceIndexPath?.row else { continue }
            item.dragItem.itemProvider.loadObject(ofClass: ProductDownloadDnD.self) { [weak self] (object, error) in
                DispatchQueue.main.async {
                    if let item = object as? ProductDownloadDnD {
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
