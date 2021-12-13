import Foundation
import UIKit

/// Command to populate the IssueRefund item quantity list selector
///
final class RefundItemQuantityListSelectorCommand: ListSelectorCommand {
    typealias Model = Int
    typealias Cell = BasicTableViewCell

    /// Navigation Bar Title
    ///
    let navigationBarTitle: String? = Localization.selectQuantityTitle

    /// Data to display
    ///
    let data: [Int]

    /// Index of the item to update
    ///
    let itemIndex: Int

    /// Holds the current selected state
    ///
    private(set) var selected: Int?

    func handleSelectedChange(selected: Int, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: Int) -> Bool {
        selected == model
    }

    func configureCell(cell: BasicTableViewCell, model: Int) {
        cell.textLabel?.text = "\(model)"
    }

    init(maxRefundQuantity: Int, currentQuantity: Int, itemIndex: Int) {
        self.selected = currentQuantity
        self.data = Array((0...maxRefundQuantity))
        self.itemIndex = itemIndex
    }
}

// MARK: Constants
private extension RefundItemQuantityListSelectorCommand {
    enum Localization {
        static let selectQuantityTitle = NSLocalizedString("Quantity to refund", comment: "Navigation title on the quantity item selector screen")
    }

}
