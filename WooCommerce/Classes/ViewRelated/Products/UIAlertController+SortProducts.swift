import UIKit
import Yosemite

extension UIAlertController {
    /// Sort Products Action Sheet
    ///
    static func presentSortProductsActionSheet(viewController: UIViewController,
                                               onSelect: @escaping (ProductsSortOrder) -> Void,
                                               onCancel: @escaping () -> Void) {
        let actionSheet = UIAlertController(title: ActionSheetStrings.title, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        let sortOrders: [ProductsSortOrder] = [.dateDescending, .dateAscending, .nameAscending, .nameDescending]

        sortOrders.forEach { sortOrder in
            actionSheet.addActionWithTitle(sortOrder.actionSheetTitle, style: .default) { _ in
                onSelect(sortOrder)
            }
        }

        actionSheet.addCancelActionWithTitle(ActionSheetStrings.cancel) { _ in
            onCancel()
        }

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = viewController.view.bounds
            popoverController.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true)
    }
}

extension ProductsSortOrder {
    var actionSheetTitle: String {
        switch self {
        case .dateAscending:
            return NSLocalizedString("Date: Oldest to Newest", comment: "Action sheet option to sort products from the oldest to the newest")
        case .dateDescending:
            return NSLocalizedString("Date: Newest to Oldest", comment: "Action sheet option to sort products from the newest to the oldest")
        case .nameAscending:
            return NSLocalizedString("Title: A to Z", comment: "Action sheet option to sort products by ascending product name")
        case .nameDescending:
            return NSLocalizedString("Title: Z to A", comment: "Action sheet option to sort products by descending product name")
        }
    }
}

private enum ActionSheetStrings {
    static let title = NSLocalizedString("Sort by",
                                         comment: "Message title for Sort Products Action Sheet")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Button title Cancel in Sort Products Action Sheet")
}
