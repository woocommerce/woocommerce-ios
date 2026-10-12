import SwiftUI
import WooFoundation

struct POSCashAmountTextField: View {
    @Binding var input: POSCashAmountInputState
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    private let formatter: POSCashAmountInputFormatter
    private let preset: Decimal?

    init(input: Binding<POSCashAmountInputState>,
         isFocused: FocusState<Bool>.Binding,
         currencySettings: CurrencySettings,
         preset: Decimal? = nil,
         onSubmit: @escaping () -> Void) {
        self._input = input
        self._isFocused = isFocused
        self.formatter = POSCashAmountInputFormatter(currencySettings: currencySettings)
        self.preset = preset
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(formatter.currencySymbol)
                .foregroundStyle(Color.posOnSurface)
                .font(.posHeadingRegular)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            TextField("", text: $input.displayText)
                .keyboardType(formatter.hasFractionDigits ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.posOnSurface)
                .font(.posHeadingRegular)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .fixedSize(horizontal: true, vertical: false)
                .disableNumberPadPopover()
                .focused($isFocused)
                .focused()
                .onSubmit {
                    onSubmit()
                }
                .onAppear {
                    if !input.hasAppliedPreset, let preset {
                        input.inputDigits = formatter.digits(from: preset)
                        let formatted = formatter.formattedAmount(from: input.inputDigits)
                        input.displayText = formatted
                        input.amount = formatted
                        input.hasAppliedPreset = true
                        input.isDisplayingPreset = true
                    }
                }
                .onDisappear {
                    isFocused = false
                }
                .onChange(of: input.displayText) { oldValue, newValue in
                    handleTextChange(oldValue: oldValue, newValue: newValue)
                }
        }
    }

    private func handleTextChange(oldValue: String, newValue: String) {
        let currentFormattedAmount = formatter.formattedAmount(from: input.inputDigits)
        guard newValue != currentFormattedAmount else {
            input.amount = currentFormattedAmount
            return
        }

        if let updatedDigits = formatter.applyingEdit(
            from: oldValue,
            to: newValue,
            currentDigits: input.inputDigits,
            isReplacingPreset: input.isDisplayingPreset
        ) {
            input.inputDigits = updatedDigits
            input.isDisplayingPreset = false
        }

        let formattedAmount = formatter.formattedAmount(from: input.inputDigits)
        input.amount = formattedAmount
        if input.displayText != formattedAmount {
            input.displayText = formattedAmount
        }
    }
}
