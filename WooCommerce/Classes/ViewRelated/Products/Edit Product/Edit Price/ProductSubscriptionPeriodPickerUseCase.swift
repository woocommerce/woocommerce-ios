import UIKit
import enum Yosemite.SubscriptionPeriod

/// Use case to handle product subscription period settings.
///
final class ProductSubscriptionPeriodPickerUseCase: NSObject {
    enum Component: Int, CaseIterable {
        case interval
        case period
    }

    typealias UpdateHandler = (_ period: SubscriptionPeriod, _ interval: String) -> Void

    let pickerView: UIPickerView = .init()

    private let updateHandler: UpdateHandler

    init(initialPeriod: SubscriptionPeriod?,
         initialInterval: String?,
         updateHandler: @escaping UpdateHandler) {
        self.updateHandler = updateHandler
        super.init()
        configurePickerView()
        preselectSubscriptionPeriodPickerRows(period: initialPeriod, interval: initialInterval)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate performance
//
extension ProductSubscriptionPeriodPickerUseCase: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        Component.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case Component.interval.rawValue:
            return Constants.maximumSubscriptionPeriodInterval
        case Component.period.rawValue:
            return SubscriptionPeriod.allCases.count
        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case Component.interval.rawValue:
            return "\(row + 1)"
        case Component.period.rawValue:
            if pickerView.selectedRow(inComponent: Component.interval.rawValue) == 0 {
                return SubscriptionPeriod.allCases[row].descriptionSingular
            } else {
                return SubscriptionPeriod.allCases[row].descriptionPlural
            }
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == Component.interval.rawValue {
            // reloads the period component to display the updated titles based on the interval.
            pickerView.reloadComponent(Component.period.rawValue)
        }
        updateSubscriptionPeriodDescription()
    }
}

// MARK: Helpers
//
private extension ProductSubscriptionPeriodPickerUseCase {

    func configurePickerView() {
        pickerView.dataSource = self
        pickerView.delegate = self
    }

    func preselectSubscriptionPeriodPickerRows(period: SubscriptionPeriod?, interval: String?) {
        let intervalRowIndex: Int = {
            guard let interval,
                  let intervalNumber = Int(interval) else {
                return 0
            }
            return intervalNumber - 1
        }()

        let periodRowIndex: Int = {
            guard let period,
                  let index = SubscriptionPeriod.allCases.firstIndex(of: period) else {
                return 0
            }
            return index
        }()

        pickerView.selectRow(intervalRowIndex,
                             inComponent: Component.interval.rawValue,
                             animated: false)
        pickerView.selectRow(periodRowIndex,
                             inComponent: Component.period.rawValue,
                             animated: false)
    }

    func updateSubscriptionPeriodDescription() {
        let selectedIntervalRow = pickerView.selectedRow(inComponent: Component.interval.rawValue)
        let selectedInterval = "\(selectedIntervalRow + 1)"

        let selectedPeriodRow = pickerView.selectedRow(inComponent: Component.period.rawValue)
        let selectedPeriod = SubscriptionPeriod.allCases[selectedPeriodRow]

        updateHandler(selectedPeriod, selectedInterval)
    }
}

private extension ProductSubscriptionPeriodPickerUseCase {
    enum Constants {
        static let maximumSubscriptionPeriodInterval = 6
    }
}
