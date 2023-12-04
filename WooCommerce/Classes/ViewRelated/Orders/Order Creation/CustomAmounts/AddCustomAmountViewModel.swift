import Combine
import WooFoundation
import UIKit
import SwiftUI
import Yosemite

/// Provides an adapter depending on the input type
///
final class AddCustomAmountInputTypeViewModelAdapterProvider {
    func provideAddCustomAmountInputTypeViewModelAdapter(with type: AddCustomAmountViewModel.InputType) -> AddCustomAmountInputTypeViewModelAdapter {
        switch type {
        case .fixedAmount:
            return FixedAmountAddCustomAmountInputTypeViewModelAdapter()
        case .orderTotalPercentage(let baseAmount):
            return PercentageAddCustomAmountInputTypeViewModelAdapter(baseAmount: baseAmount)
        }
    }
}

/// Classes implementing this protocol will act as an adapter between `AddCustomAmountViewModel` and the input type view models.
/// This way, the former can be agnostic of what type of view model we have before the scenes,
/// and doesn't have to type check to access their concrete implementation.
/// Having a adapter keeps the classes loosely coupled, as the type view model doesn't have to adapt for `AddCustomAmountViewModel`,
/// the adapter implements this adaptation.
///
protocol AddCustomAmountInputTypeViewModelAdapter {
    var amount: String? { get }
    var amountPublisher: Published<String>.Publisher? { get }
    var viewModel: AddCustomAmountViewModel? { get set }

    func preset(with fee: OrderFeeLine)
}

struct FixedAmountAddCustomAmountInputTypeViewModelAdapter: AddCustomAmountInputTypeViewModelAdapter {
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

struct PercentageAddCustomAmountInputTypeViewModelAdapter: AddCustomAmountInputTypeViewModelAdapter {
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

    private var inputTypeViewModelAdapter: AddCustomAmountInputTypeViewModelAdapter
    private let onCustomAmountEntered: CustomAmountEntered
    private let onCustomAmountDeleted: ((_ fee: Int64) -> Void)?
    private let analytics: Analytics
    let currencyFormatter: CurrencyFormatter
    var formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel?
    var percentageViewModel: AddCustomAmountPercentageViewModel?

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
    @Published private(set) var shouldEnableDoneButton: Bool = false
    @Published var isTaxable: Bool = true
    private var feeID: Int64? = nil

    var customAmountPlaceholder: String {
        Localization.customAmountPlaceholder
    }

    var shouldShowDeleteButton: Bool {
        isInEditMode
    }

    private var isInEditMode: Bool {
        feeID != nil
    }

    var doneButtonTitle: String {
        return isInEditMode ? Localization.editButtonTitle : Localization.addButtonTitle
    }

    init(inputType: InputType,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         onCustomAmountDeleted: ((_ fee: Int64) -> Void)? = nil,
         onCustomAmountEntered: @escaping CustomAmountEntered) {
        self.inputTypeViewModelAdapter = AddCustomAmountInputTypeViewModelAdapterProvider().provideAddCustomAmountInputTypeViewModelAdapter(with: inputType)
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        self.analytics = analytics
        self.onCustomAmountDeleted = onCustomAmountDeleted
        self.onCustomAmountEntered = onCustomAmountEntered

        setupViewModels(from: inputType, locale: locale, storeCurrencySettings: storeCurrencySettings)
        inputTypeViewModelAdapter.viewModel = self

        listenToAmountChanges()
    }

    func doneButtonPressed() {
        guard let amount = inputTypeViewModelAdapter.amount else { return }
        trackEventsOnDoneButtonPressed()

        let customAmountName = name.isNotEmpty ? name : customAmountPlaceholder
        onCustomAmountEntered(amount, customAmountName, feeID, isTaxable)
    }

    func deleteButtonPressed() {
        guard let feeID = feeID else {
            DDLogError("Failed attempt to delete feeID \(String(describing: feeID))")
            return
        }
        onCustomAmountDeleted?(feeID)
    }

    func preset(with fee: OrderFeeLine) {
        name = fee.name ?? Localization.customAmountPlaceholder
        inputTypeViewModelAdapter.preset(with: fee)
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
        inputTypeViewModelAdapter.amountPublisher?.map { [weak self] value in
            guard let self = self else { return false }

            return self.amountIsValid(amount: value)
        }.assign(to: &$shouldEnableDoneButton)
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
