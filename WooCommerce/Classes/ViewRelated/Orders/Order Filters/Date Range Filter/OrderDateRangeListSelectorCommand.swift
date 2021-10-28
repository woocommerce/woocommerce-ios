import Foundation
import Observables
import SwiftUI

/// Command to populate the order list date range filter list selector
///
final class OrderDateRangeListSelectorCommand: ListSelectorCommand {
    typealias Cell = BasicTableViewCell
    typealias Model = OrderDateRangeFilterEnum

    let navigationBarTitle: String? = Localization.navigationBarTitle

    /// Holds the current selected state
    ///
    private(set) var selected: OrderDateRangeFilterEnum? = .any

    fileprivate(set) var data: [OrderDateRangeFilterEnum]

    init(data: [OrderDateRangeFilterEnum], selected: OrderDateRangeFilterEnum?) {
        self.data = data
        self.selected = selected ?? .any
    }

    func isSelected(model: OrderDateRangeFilterEnum) -> Bool {
        selected == model
    }

    func handleSelectedChange(selected: OrderDateRangeFilterEnum, viewController: ViewController) {

        guard selected != .custom else {
            // Open the list selector for selecting a custom range of dates
            let command = OrderCustomRangeListSelectorCommand(data: [.start(nil), .end(nil)])
            let listSelector = ListSelectorViewController(command: command, tableViewStyle: .plain) { [weak self] selectedOptions in
                //TODO: handle selection
            }
            viewController.navigationController?.pushViewController(listSelector, animated: true)
            return
        }

        self.selected = selected
    }

    func configureCell(cell: BasicTableViewCell, model: OrderDateRangeFilterEnum) {
        cell.textLabel?.text = model.description

        switch model {
        case .custom:
            cell.accessoryType = selected == .custom ? .checkmark : .disclosureIndicator
        default:
            cell.accessoryType = isSelected(model: model) ? .checkmark : .none
        }
    }
}

private extension OrderDateRangeListSelectorCommand {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Date Range", comment: "Navigation title of the orders filter selector screen for date range")
    }
}
