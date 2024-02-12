import Foundation
import UIKit

/// Coordinates navigation into Custom Range tab creation from the Stats dashboard.
final class CustomRangeTabCreationCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        presentDateRangePicker()
    }
}

private extension CustomRangeTabCreationCoordinator {
    func presentDateRangePicker() {
        let controller = RangedDatePickerHostingController(datesFormatter: DatesFormatter()) { [weak self] _, _ in
            guard let self else { return }
            // TODO call function to handle range selection.
        }
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
