import Foundation
import SwiftUI

/// Command to populate the order list custom date range filter list selector
///
final class OrderCustomRangeListSelectorCommand: ListSelectorCommand {
    typealias Cell = TitleAndValueTableViewCell
    typealias Model = OrderCustomRangeFilterEnum

    let navigationBarTitle: String? = Localization.navigationBarTitle

    // Timezone of the website
    //
    private let timezone = TimeZone.siteTimezone

    /// Holds the current selected state
    ///
    private(set) var selected: OrderCustomRangeFilterEnum? = nil

    fileprivate(set) var data: [OrderCustomRangeFilterEnum]

    init(data: [OrderCustomRangeFilterEnum], selected: OrderCustomRangeFilterEnum?) {
        self.data = data
        self.selected = selected
    }

    func isSelected(model: OrderCustomRangeFilterEnum) -> Bool {
        selected == model
    }

    func handleSelectedChange(selected: OrderCustomRangeFilterEnum, viewController: ViewController) {

        self.selected = selected
    }

    func configureCell(cell: TitleAndValueTableViewCell, model: OrderCustomRangeFilterEnum) {
        cell.selectionStyle = .default
        cell.updateUI(title: model.description, value: model.value?.toString(dateStyle: .medium, timeStyle: .none, timeZone: timezone))
        cell.accessoryType = .disclosureIndicator
    }
}

private extension OrderCustomRangeListSelectorCommand {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Custom Range",
                                                          comment: "Navigation title of the orders filter selector screen for custom date range")
    }
}
