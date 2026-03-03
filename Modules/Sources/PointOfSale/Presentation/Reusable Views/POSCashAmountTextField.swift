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
        TextField("", text: $displayText)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.posOnSurface)
            .font(.posHeadingRegular)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .disableNumberPadPopover()
            .focused($isFocused)
            .focused()
            .onSubmit {
                onSubmit()
            }
            .onAppear {
                if !hasAppliedPreset, let preset {
                    let formatted = sanitizer.formatDecimal(preset)
                    displayText = sanitizer.addCurrencySymbol(to: formatted)
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

    private func handleTextChange(oldValue: String, newValue: String) {
        let strippedNew = stripCurrencySymbol(from: newValue)

        if let sanitized = sanitizer.sanitize(strippedNew) {
            amount = sanitized
            let withSymbol = sanitizer.addCurrencySymbol(to: sanitized)
            if displayText != withSymbol {
                displayText = withSymbol
            }
        } else {
            displayText = oldValue
        }
    }

    private func stripCurrencySymbol(from text: String) -> String {
        var stripped = text
        let symbol = sanitizer.currencySymbol
        stripped = stripped.replacingOccurrences(of: symbol, with: "")
        stripped = stripped.replacingOccurrences(of: "\u{00a0}", with: "")
        stripped = stripped.trimmingCharacters(in: .whitespaces)
        return stripped
    }
}
