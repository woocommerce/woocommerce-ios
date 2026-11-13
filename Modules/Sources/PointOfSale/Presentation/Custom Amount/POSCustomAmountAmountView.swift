import SwiftUI
import WooFoundation

/// First step of the custom amount flow: amount entry with the cash checkout input.
struct POSCustomAmountAmountView: View {
    @Environment(\.posMetrics) private var metrics

    let viewModel: AddCustomAmountFormViewModel
    let currencySettings: CurrencySettings
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var amountInput = POSCashAmountInputState()
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                backButtonConfiguration: .init(state: .enabled, action: {
                    isAmountFocused = false
                    onBack()
                })
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
                Text(Localization.continueButton)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.isAddEnabled)
            .accessibilityIdentifier("pos-custom-amount-continue-button")
            .padding(metrics.padding.medium)
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .onChange(of: amountInput.inputDigits) { _, digits in
            viewModel.setAmount(digits: digits)
        }
    }

    private func continueIfValid() {
        guard viewModel.isAddEnabled else { return }
        onContinue()
    }
}

private extension POSCustomAmountAmountView {
    enum Localization {
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
        onBack: {},
        onContinue: {}
    )
}
#endif
