import SwiftUI
import WooFoundation

struct POSCashAmountTextField: View {
    @Binding var amount: String
    @FocusState.Binding var isFocused: Bool
    let onSubmit: () -> Void

    @State private var displayText: String = ""
    @State private var inputDigits: String = ""
    @State private var hasAppliedPreset: Bool = false
    @State private var isDisplayingPreset: Bool = false

    private let formatter: POSCashAmountInputFormatter
    private let preset: Decimal?

    init(amount: Binding<String>,
         isFocused: FocusState<Bool>.Binding,
         currencySettings: CurrencySettings,
         preset: Decimal? = nil,
         onSubmit: @escaping () -> Void) {
        self._amount = amount
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
            TextField("", text: $displayText)
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
                    if !hasAppliedPreset, let preset {
                        inputDigits = formatter.digits(from: preset)
                        let formatted = formatter.formattedAmount(from: inputDigits)
                        displayText = formatted
                        amount = formatted
                        hasAppliedPreset = true
                        isDisplayingPreset = true
                    }
                }
                .onDisappear {
                    isFocused = false
                }
                .onChange(of: displayText) { oldValue, newValue in
                    handleTextChange(oldValue: oldValue, newValue: newValue)
                }
        }
    }

    private func handleTextChange(oldValue: String, newValue: String) {
        let currentFormattedAmount = formatter.formattedAmount(from: inputDigits)
        guard newValue != currentFormattedAmount else {
            amount = currentFormattedAmount
            return
        }

        if let updatedDigits = formatter.applyingEdit(
            from: oldValue,
            to: newValue,
            currentDigits: inputDigits,
            isReplacingPreset: isDisplayingPreset
        ) {
            inputDigits = updatedDigits
            isDisplayingPreset = false
        }

        let formattedAmount = formatter.formattedAmount(from: inputDigits)
        amount = formattedAmount
        if displayText != formattedAmount {
            displayText = formattedAmount
        }
    }
}
