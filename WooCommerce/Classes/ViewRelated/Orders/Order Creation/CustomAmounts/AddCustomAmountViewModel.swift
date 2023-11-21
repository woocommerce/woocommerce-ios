import Combine
import WooFoundation
import UIKit
import SwiftUI
import Yosemite

final class AddCustomAmountInputTypeViewModelProxyProvider {
    func provideAddCustomAmountInputTypeViewModelProxy(with type: AddCustomAmountViewModel.InputType) -> AddCustomAmountInputTypeViewModelProxy {
        switch type {
        case .fixedAmount:
            return FixedAddCustomAmountInputTypeViewModelProxy()
        case .orderTotalPercentage(let baseAmount):
            return PercentageAddCustomAmountInputTypeViewModelProxy(baseAmount: baseAmount)
        }
    }
}

protocol AddCustomAmountInputTypeViewModelProxy {
    var amount: String? { get }
    var amountPublisher: Published<String>.Publisher? { get }
    var viewModel: AddCustomAmountViewModel? { get set }

    func preset(with fee: OrderFeeLine)
}

struct FixedAddCustomAmountInputTypeViewModelProxy: AddCustomAmountInputTypeViewModelProxy {
    weak var viewModel: AddCustomAmountViewModel?

    var amount: String? {
        viewModel?.formattableAmountTextFieldViewModel?.amount
    }

    var amountPublisher: Published<String>.Publisher? {
        viewModel?.formattableAmountTextFieldViewModel?.$amount
    }

    func preset(with fee: OrderFeeLine) {
        viewModel?.formattableAmountTextFieldViewModel?.presetAmount(fee.total)
    }
}

struct PercentageAddCustomAmountInputTypeViewModelProxy: AddCustomAmountInputTypeViewModelProxy {
    weak var viewModel: AddCustomAmountViewModel?
    let baseAmount: Decimal

    var amountPublisher: Published<String>.Publisher? {
        viewModel?.percentageViewModel?.$percentageCalculatedAmount
    }

    var amount: String? {
        viewModel?.percentageViewModel?.percentageCalculatedAmount
    }

    func preset(with fee: OrderFeeLine) {
        viewModel?.percentageViewModel?.preset(with: fee)
    }
}

typealias CustomAmountEntered = (_ amount: String, _ name: String, _ feeID: Int64?, _ isTaxable: Bool) -> Void

final class AddCustomAmountViewModel: ObservableObject {
    enum InputType {
        case fixedAmount
        case orderTotalPercentage(baseAmount: Decimal)
    }

    private let inputType: InputType
    private var inputTypeVieModelProxy: AddCustomAmountInputTypeViewModelProxy
    private let onCustomAmountEntered: CustomAmountEntered
    private let analytics: Analytics
    let currencyFormatter: CurrencyFormatter
    var formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel?
    var percentageViewModel: AddCustomAmountPercentageViewModel?

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
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

    init(inputType: InputType,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         onCustomAmountEntered: @escaping CustomAmountEntered) {
        self.inputTypeVieModelProxy = AddCustomAmountInputTypeViewModelProxyProvider().provideAddCustomAmountInputTypeViewModelProxy(with: inputType)
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        self.inputType = inputType
        self.analytics = analytics
        self.onCustomAmountEntered = onCustomAmountEntered

        setupViewModels(from: inputType, locale: locale, storeCurrencySettings: storeCurrencySettings)
        inputTypeVieModelProxy.viewModel = self


        listenToAmountChanges()
    }

    func doneButtonPressed() {
        guard let amount = inputTypeVieModelProxy.amount else { return }
        trackEventsOnDoneButtonPressed()

        let customAmountName = name.isNotEmpty ? name : customAmountPlaceholder
        onCustomAmountEntered(amount, customAmountName, feeID, isTaxable)
    }


    func preset(with fee: OrderFeeLine) {
        name = fee.name ?? Localization.customAmountPlaceholder
        inputTypeVieModelProxy.preset(with: fee)
        feeID = fee.feeID
    }
}

private extension AddCustomAmountViewModel {
    func setupViewModels(from type: InputType, locale: Locale, storeCurrencySettings: CurrencySettings) {
        switch type {
        case .fixedAmount:
            formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        case .orderTotalPercentage(let baseAmount):
            percentageViewModel = AddCustomAmountPercentageViewModel(baseAmountForPercentage: baseAmount, currencyFormatter: currencyFormatter)
        }
    }

    func listenToAmountChanges() {
        inputTypeVieModelProxy.amountPublisher?.map { [weak self] value in
            !(self?.amountIsValid(amount: value) ?? true)
        }.assign(to: &$shouldDisableDoneButton)
    }

    func amountIsValid(amount: String) -> Bool {
        guard let decimalAmount = currencyFormatter.convertToDecimal(amount) as? Decimal else { return false }

        return decimalAmount > .zero
    }

    func trackEventsOnDoneButtonPressed() {
        if name.isNotEmpty {
            analytics.track(.addCustomAmountNameAdded)
        }

        if percentageViewModel?.percentage.isNotEmpty ?? false {
            analytics.track(.addCustomAmountPercentageAdded)
        }

        analytics.track(.addCustomAmountDoneButtonTapped)
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
