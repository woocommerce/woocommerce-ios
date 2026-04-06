import SwiftUI
import WooFoundation

struct POSCashAmountTextField: View {
    @Binding var amount: String
    @FocusState.Binding var isFocused: Bool
    let sanitizer: CurrencyInputSanitizer
    let onSubmit: () -> Void

    @State private var displayText: String = ""
    @State private var hasAppliedPreset: Bool = false

    private let preset: Decimal?

    init(amount: Binding<String>,
         isFocused: FocusState<Bool>.Binding,
         sanitizer: CurrencyInputSanitizer,
         preset: Decimal? = nil,
         onSubmit: @escaping () -> Void) {
        self._amount = amount
        self._isFocused = isFocused
        self.sanitizer = sanitizer
        self.preset = preset
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(sanitizer.currencySymbol)
                .foregroundStyle(Color.posOnSurface)
                .font(.posHeadingRegular)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            TextField("", text: $displayText)
                .keyboardType(.decimalPad)
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
                        let formatted = sanitizer.formatDecimal(preset)
                        displayText = formatted
                        amount = formatted
                        hasAppliedPreset = true
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
        if let sanitized = sanitizer.sanitize(newValue) {
            amount = sanitized
            if displayText != sanitized {
                displayText = sanitized
            }
        } else {
            displayText = oldValue
        }
    }
}
