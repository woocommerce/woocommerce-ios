import SwiftUI

/// Provide access to FormattableAmountTextField and ViewModel for POS without making it as an explicit type dependency
/// FormattableAmountTextField cannot be easily moved and reused in a shared module due to multiple dependencies
/// This is used as a workaround to enable POS modularization without requiring a larger refactoring effort
///
struct POSFormattableAmountTextFieldAdaptor: View {
    @StateObject private var textFieldViewModel: FormattableAmountTextFieldViewModel
    private let preset: Decimal?
    private let style: FormattableAmountTextField.Style
    private let onSubmit: () -> Void
    private let onChange: (String) -> Void

    init(preset: Decimal?, font: Font, onSubmit: @escaping () -> Void, onChange: @escaping (String) -> Void) {
        self._textFieldViewModel = StateObject(wrappedValue: FormattableAmountTextFieldViewModel(
            size: .extraLarge,
            locale: Locale.autoupdatingCurrent,
            storeCurrencySettings: ServiceLocator.currencySettings,
            allowNegativeNumber: false)
        )
        self.preset = preset
        self.style = .init(showsBorder: false, textAlignment: .center, font: font)
        self.onSubmit = onSubmit
        self.onChange = onChange
    }

    var body: some View {
        FormattableAmountTextField(viewModel: textFieldViewModel, style: style)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .onSubmit {
                onSubmit()
            }
            .onChange(of: textFieldViewModel.amount) { _, newValue in
                onChange(newValue)
            }
            .onAppear {
                if let preset {
                    textFieldViewModel.presetAmount(preset)
                }
            }
    }
}
