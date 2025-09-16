import SwiftUI

/// Provide access to FormattableAmountTextField and ViewModel for POS without making it as an explicit type dependency
/// FormattableAmountTextField cannot be easily moved and reused in a shared module due to multiple dependencies
/// This is used as a workaround to enable POS modularization without requiring a larger refactoring effort
///
struct POSFormattableAmountTextFieldAdaptor: View {
    @StateObject private var textFieldViewModel: FormattableAmountTextFieldViewModel
    let preset: Decimal?
    let onSubmit: () -> Void
    let onChange: (String) -> Void

    init(preset: Decimal?, onSubmit: @escaping () -> Void, onChange: @escaping (String) -> Void) {
        self._textFieldViewModel = StateObject(wrappedValue: FormattableAmountTextFieldViewModel(
            size: .extraLarge,
            locale: Locale.autoupdatingCurrent,
            storeCurrencySettings: ServiceLocator.currencySettings,
            allowNegativeNumber: false)
        )
        self.preset = preset
        self.onSubmit = onSubmit
        self.onChange = onChange
    }

    var body: some View {
        FormattableAmountTextField(viewModel: textFieldViewModel, style: .pos)
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
