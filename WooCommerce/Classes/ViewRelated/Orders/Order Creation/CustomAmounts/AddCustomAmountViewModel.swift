import Combine
import WooFoundation
import UIKit
import SwiftUI
import Yosemite

typealias CustomAmountEntered = (_ amount: String, _ name: String, _ feeID: Int64?, _ isTaxable: Bool) -> Void

final class AddCustomAmountViewModel: ObservableObject {
    enum InputType {
        case fixedAmount
        case orderTotalPercentage(baseAmount: Decimal)
    }

    let formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel

    private let inputType: InputType
    private let onCustomAmountEntered: CustomAmountEntered
    private let analytics: Analytics
    private let currencyFormatter: CurrencyFormatter
    private let priceFieldFormatter: PriceFieldFormatter

    @Published var percentageCalculatedAmount: String = "" {
        didSet {
            guard percentageCalculatedAmount != oldValue else { return }

            percentageCalculatedAmount = priceFieldFormatter.formatAmount(percentageCalculatedAmount)
        }
    }

    var shouldShowPercentageInput: Bool {
        guard case .orderTotalPercentage = inputType else {
            return false
        }

        return true
    }

    var shouldShowFixedAmountInput: Bool {
        guard case .fixedAmount = inputType else {
            return false
        }

        return true
    }

    var baseAmountForPercentageString: String {
        guard case let .orderTotalPercentage(baseAmountForPercentage) = inputType,
              let formattedAmount = currencyFormatter.formatAmount(baseAmountForPercentage) else {
            return ""
        }

        return formattedAmount
    }

    init(inputType: InputType,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         onCustomAmountEntered: @escaping CustomAmountEntered) {
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.inputType = inputType
        self.formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.analytics = analytics
        self.onCustomAmountEntered = onCustomAmountEntered
        listenToAmountChanges()

        percentageCalculatedAmount = "0"
    }

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
    @Published var percentage = "" {
        didSet {
            guard oldValue != percentage else { return }

            presetAmountBasedOnPercentage(percentage)
        }
    }

    @Published private(set) var shouldDisableDoneButton: Bool = true
    @Published var isTaxable: Bool = true
    private var feeID: Int64? = nil

    var customAmountPlaceholder: String {
        Localization.customAmountPlaceholder
    }

    var doneButtonTitle: String {
        let isInEditMode = feeID != nil
        return isInEditMode ? Localization.editButtonTitle : Localization.addButtonTitle
    }

    func doneButtonPressed() {
        trackEventsOnDoneButtonPressed()

        let customAmountName = name.isNotEmpty ? name : customAmountPlaceholder
        onCustomAmountEntered(formattableAmountTextFieldViewModel.amount, customAmountName, feeID, isTaxable)
    }


    func preset(with fee: OrderFeeLine) {
        name = fee.name ?? Localization.customAmountPlaceholder
        formattableAmountTextFieldViewModel.presetAmount(fee.total)
        feeID = fee.feeID
    }
}

private extension AddCustomAmountViewModel {
    func listenToAmountChanges() {
        formattableAmountTextFieldViewModel.$amount.map { _ in
            !self.formattableAmountTextFieldViewModel.amountIsValid
        }.assign(to: &$shouldDisableDoneButton)
    }

    func trackEventsOnDoneButtonPressed() {
        if name.isNotEmpty {
            analytics.track(.addCustomAmountNameAdded)
        }

        if percentage.isNotEmpty {
            analytics.track(.addCustomAmountPercentageAdded)
        }

        analytics.track(.addCustomAmountDoneButtonTapped)
    }

    func presetAmountBasedOnPercentage(_ percentage: String) {
        guard case let .orderTotalPercentage(baseAmountForPercentage) = inputType,
              let decimalInput = currencyFormatter.convertToDecimal(percentage) else { return }

        percentageCalculatedAmount = "\(baseAmountForPercentage * (decimalInput as Decimal) * 0.01)"
    }
}

private extension AddCustomAmountViewModel {
    enum Localization {
        static let addButtonTitle = NSLocalizedString("addCustomAmount.doneButton",
                                                       value: "Add Custom Amount",
                                                       comment: "Button title to confirm the custom amount on the add custom amount view in orders.")
        static let editButtonTitle = NSLocalizedString("addCustomAmount.editButton",
                                                       value: "Edit Custom Amount",
                                                       comment: "Button title to confirm the custom amount on the edit custom amount view in orders.")
        static let customAmountPlaceholder = NSLocalizedString("Custom amount",
                                                               comment: "Placeholder for the name field on the add custom amount view in orders.")
    }
}
