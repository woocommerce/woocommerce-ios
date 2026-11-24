import SwiftUI
import WooFoundation

/// First step of the custom amount flow: amount entry with the cash checkout input.
struct POSCustomAmountAmountView: View {
    @Environment(\.posMetrics) private var metrics

    enum Mode {
        case initial
        case edit
    }

    @State private var viewModel: AddCustomAmountFormViewModel
    let currencySettings: CurrencySettings
    let onBack: () -> Void
    let onSave: (String) -> Void
    let mode: Mode

    @State private var amountInput = POSCashAmountInputState()
    @FocusState private var isAmountFocused: Bool

    init(viewModel: AddCustomAmountFormViewModel, currencySettings: CurrencySettings, mode: Mode,
         onBack: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        self._viewModel = State(initialValue: viewModel.makeAmountDraft())
        self.currencySettings = currencySettings
        self.mode = mode
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: mode == .initial ? Localization.title : AddCustomAmountView.Localization.editAmount,
                backButtonConfiguration: .init(state: .enabled, action: goBack)
            )

            Spacer()

            POSCashAmountTextField(
                input: $amountInput,
                isFocused: $isAmountFocused,
                currencySettings: currencySettings,
                onSubmit: continueIfValid
            )
            .accessibilityIdentifier("pos-custom-amount-amount-input")

            Spacer()

            Button(action: continueIfValid) {
                Text(mode == .initial ? Localization.continueButton : Localization.saveButton)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.isAddEnabled)
            .accessibilityIdentifier(mode == .initial ? "pos-custom-amount-continue-button" : "pos-custom-amount-save-button")
            .padding(metrics.padding.medium)
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .onAppear {
            amountInput = viewModel.makeAmountInputState()
        }
        .posEdgeSwipeBackAction(onBack: goBack)
        .onChange(of: amountInput.inputDigits) { _, digits in
            viewModel.setAmount(digits: digits)
        }
    }

    private func goBack() {
        isAmountFocused = false
        onBack()
    }

    private func continueIfValid() {
        guard viewModel.isAddEnabled else { return }
        isAmountFocused = false
        onSave(viewModel.amount)
    }
}

extension POSCustomAmountAmountView {
    enum Localization {
        static let saveButton = NSLocalizedString(
            "pos.customAmount.amountStep.saveButton", value: "Save",
            comment: "Button that saves an edited custom amount and returns to its details.")
        static let title = NSLocalizedString(
            "pos.customAmount.amountStep.title",
            value: "Amount",
            comment: "Title of the Point of Sale screen where the merchant enters the value of a new custom amount.")
        static let continueButton = NSLocalizedString(
            "pos.customAmount.amountStep.continueButton",
            value: "Continue",
            comment: "Button on the Point of Sale custom amount entry screen that goes to the next step of the flow.")
    }
}

#if DEBUG
#Preview {
    POSCustomAmountAmountView(
        viewModel: AddCustomAmountFormViewModel(currencySettings: CurrencySettings()),
        currencySettings: CurrencySettings(),
        mode: .initial,
        onBack: {},
        onSave: { _ in }
    )
}
#endif
