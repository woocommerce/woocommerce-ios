import Foundation
import UIKit

/// Coordinates navigation into Custom Range tab creation from the Stats dashboard.
final class CustomRangeTabCreationCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let onDateRangeSelected: (_ start: Date, _ end: Date) -> Void

    init(navigationController: UINavigationController, onDateRangeSelected: @escaping (_ start: Date, _ end: Date) -> Void) {
        self.navigationController = navigationController
        self.onDateRangeSelected = onDateRangeSelected
    }

    func start() {
        presentDateRangePicker()
    }
}

private extension CustomRangeTabCreationCoordinator {
    func presentDateRangePicker() {
        let controller = RangedDatePickerHostingController(
            datesFormatter: DatesFormatter(),
            customApplyButtonTitle: Localization.add,
            datesSelected: { [weak self] start, end in
                guard let self else { return }
                self.onDateRangeSelected(start, end)
            }
        )

        navigationController.present(controller, animated: true)
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
    enum Localization {
        static let add = NSLocalizedString(
            "customRangeTabCreationCoordinator.add",
            value: "Add",
            comment: "Button in date range picker to add a Custom Range tab"
        )
    }
}
