import SwiftUI

/// This numeric Text Field updates the user input to show the formatted amount
///
struct FormattableAmountTextField: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @State var focusAmountInput: Bool = true

    @ObservedObject private var viewModel: FormattableAmountTextFieldViewModel

    init(viewModel: FormattableAmountTextFieldViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Hidden input text field
            BindableTextfield("", text: $viewModel.amount, focus: $focusAmountInput)
                .keyboardType(viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
                .opacity(0)

            // Visible & formatted label
            Text(viewModel.formattedAmount)
                .font(.system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
                .foregroundColor(Color(viewModel.amountTextColor))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .onTapGesture {
                    focusAmountInput = true
                }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension FormattableAmountTextField {
    enum Layout {
        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }
    }
}
