import Foundation
import Observables
import SwiftUI

/// Command to populate the order list date range filter list selector
///
final class OrderDateRangeListSelectorCommand: ListSelectorCommand {
    typealias Cell = BasicTableViewCell
    typealias Model = OrderDateRangeFilter

    let navigationBarTitle: String? = Localization.navigationBarTitle

    /// Holds the current selected state
    ///
    private(set) var selected: OrderDateRangeFilter? = OrderDateRangeFilter(filter: .any)

    fileprivate(set) var data: [OrderDateRangeFilter]

    init(data: [OrderDateRangeFilter], selected: OrderDateRangeFilter?) {
        self.data = data
        self.selected = selected ?? OrderDateRangeFilter(filter: .any)
    }

    func isSelected(model: OrderDateRangeFilter) -> Bool {
        selected?.filter == model.filter && selected?.filter != OrderDateRangeFilter(filter: .custom).filter
    }

    func handleSelectedChange(selected: OrderDateRangeFilter, viewController: ViewController) {
        switch selected.filter {
        case .custom:
            // Open the View Controller for selecting a custom range of dates
            //
            let dateRangeFilterVC = DateRangeFilterViewController(startDate: selected.startDate, endDate: selected.endDate) { (startDate, endDate) in
                self.selected = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)
            }
            viewController.navigationController?.pushViewController(dateRangeFilterVC, animated: true)
        default:
            self.selected = selected
        }
    }

    func configureCell(cell: BasicTableViewCell, model: OrderDateRangeFilter) {
        cell.textLabel?.text = model.description

        switch model.filter {
        case .custom:
            cell.accessoryType = isSelected(model: model) ? .checkmark : .disclosureIndicator
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
