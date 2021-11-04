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

    /// Holds the current selected state. Unused and implemented just for the conformance to `ListSelectorCommand`.
    ///
    private(set) var selected: OrderCustomRangeFilterEnum? = nil

    // Completion callback
    //
    typealias Completion = (_ dateRange: (Date, Date)) -> Void
    private let onCompletion: Completion

    private var startDate: Date?
    private var endDate: Date?

    fileprivate(set) var data: [OrderCustomRangeFilterEnum]

    init(data: [OrderCustomRangeFilterEnum],
         startDate: Date?,
         endDate: Date?,
         completion: @escaping Completion) {
        self.data = data
        self.startDate = startDate
        self.endDate = endDate
        onCompletion = completion
    }

    func isSelected(model: OrderCustomRangeFilterEnum) -> Bool {
        false
    }

    func handleSelectedChange(selected: OrderCustomRangeFilterEnum, viewController: ViewController) {
        var picker: DatePickerViewController
        switch selected {
        case .start:
            picker = DatePickerViewController(date: startDate, datePickerMode: .date, minimumDate: nil, maximumDate: endDate) { [weak self] date in
                self?.startDate = date
            }
        case .end:
            picker = DatePickerViewController(date: endDate, datePickerMode: .date, minimumDate: startDate, maximumDate: nil) { [weak self] date in
                self?.endDate = date
            }
            viewController.present(picker, animated: true)
        }
    }

    func configureCell(cell: TitleAndValueTableViewCell, model: OrderCustomRangeFilterEnum) {

        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator

        switch model {
        case .start:
            cell.updateUI(title: model.description, value: startDate?.toString(dateStyle: .medium, timeStyle: .none, timeZone: timezone))
        case .end:
            cell.updateUI(title: model.description, value: endDate?.toString(dateStyle: .medium, timeStyle: .none, timeZone: timezone))
        }
    }
}

private extension OrderCustomRangeListSelectorCommand {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Custom Range",
                                                          comment: "Navigation title of the orders filter selector screen for custom date range")
    }
}
