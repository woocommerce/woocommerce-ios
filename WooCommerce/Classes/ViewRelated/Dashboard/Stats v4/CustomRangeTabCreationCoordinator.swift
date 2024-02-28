import Foundation
import UIKit

/// Coordinates navigation into Custom Range tab creation from the Stats dashboard.
final class CustomRangeTabCreationCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let startDate: Date?
    private let endDate: Date?
    private let onDateRangeSelected: (_ start: Date, _ end: Date) -> Void

    init(startDate: Date?,
         endDate: Date?,
         navigationController: UINavigationController,
         onDateRangeSelected: @escaping (_ start: Date, _ end: Date) -> Void) {
        self.startDate = startDate
        self.endDate = endDate
        self.navigationController = navigationController
        self.onDateRangeSelected = onDateRangeSelected
    }

    func start() {
        presentDateRangePicker()
    }
}

private extension CustomRangeTabCreationCoordinator {
    func presentDateRangePicker() {
        let buttonTitle = (startDate == nil && endDate == nil) ? Localization.add : nil
        let endDate = self.endDate ?? Date()
        let startDate = self.startDate ?? Date(timeInterval: -Constants.thirtyDaysInSeconds, since: endDate) // 30 days before end date
        let controller = RangedDatePickerHostingController(
            startDate: startDate,
            endDate: endDate,
            datesFormatter: DatesFormatter(),
            customApplyButtonTitle: buttonTitle,
            datesSelected: { [weak self] start, end in
                guard let self else { return }
                guard start < end else {
                    self.presentInvalidTimeRangeAlert()
                    return
                }
                self.onDateRangeSelected(start, end)
            }
        )

        navigationController.present(controller, animated: true)
    }

    func presentInvalidTimeRangeAlert() {
        let alert = UIAlertController(title: Localization.InvalidTimeRangeAlert.title,
                                      message: Localization.InvalidTimeRangeAlert.message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localization.InvalidTimeRangeAlert.action, style: .cancel))
        navigationController.present(alert, animated: true)
    }

    /// Specific `DatesFormatter` for the `RangedDatePicker` when presented in the analytics hub module.
    ///
    struct DatesFormatter: RangedDateTextFormatter {
        func format(start: Date, end: Date) -> String {
            start.formatAsRange(with: end, timezone: .current, calendar: Locale.current.calendar)
        }
    }
}

// MARK: Constant

private extension CustomRangeTabCreationCoordinator {
    enum Constants {
        static let thirtyDaysInSeconds: TimeInterval = 86400*30
    }
    enum Localization {
        static let add = NSLocalizedString(
            "customRangeTabCreationCoordinator.add",
            value: "Add",
            comment: "Button in date range picker to add a Custom Range tab"
        )
        enum InvalidTimeRangeAlert {
            static let title = NSLocalizedString(
                "customRangeTabCreationCoordinator.invalidTimeRangeAlert.title",
                value: "Invalid time range",
                comment: "Title of the alert displayed when selecting an invalid time range for My Store Analytics"
            )
            static let message = NSLocalizedString(
                "customRangeTabCreationCoordinator.invalidTimeRangeAlert.message",
                value: "The start date should be earlier than the end date. Please select a different time range.",
                comment: "Message of the alert displayed when selecting an invalid time range for My Store Analytics"
            )
            static let action = NSLocalizedString(
                "customRangeTabCreationCoordinator.invalidTimeRangeAlert.action",
                value: "Got It",
                comment: "Button to dismiss the alert displayed when selecting an invalid time range for My Store Analytics"
            )
        }
    }
}
