import SwiftUI

/// This numeric Text Field updates the user input to show the formatted amount
///
struct OldFormattableAmountTextField: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var focusAmountInput: Bool

    @ObservedObject private var viewModel: FormattableAmountTextFieldViewModel

    init(viewModel: FormattableAmountTextFieldViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Hidden input text field
            TextField("", text: $viewModel.textFieldAmountText)
                .onChange(of: viewModel.textFieldAmountText, perform: viewModel.updateAmount)
                .onChange(of: focusAmountInput) {
                    viewModel.isFocused = $0
                }
                .focused($focusAmountInput)
                .keyboardType(viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
                .opacity(0)

            Text(viewModel.formattedAmount)
                .font(.system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
                .foregroundColor(Color(viewModel.amountTextColor))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    focusAmountInput = true
                }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension OldFormattableAmountTextField {
    enum Layout {
        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }
    }
}

// This new version shows the cursor
struct FormattableAmountTextField: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var input: String = ""

    @ObservedObject private var viewModel: FormattableAmountTextFieldViewModel

        init(viewModel: FormattableAmountTextFieldViewModel) {
            self.viewModel = viewModel
        }

    var body: some View {
        VStack {
            TextField(viewModel.formattedAmount, text: $input)
                .keyboardType(viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
            .padding()
            .font(.system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
            .foregroundColor(Color(viewModel.amountTextColor))
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: input) { newValue in
                // This is the logic: format the new value and asign it to the input if it was actually update (Assigning it when it wasn't updated causes
                // unexpected results
                if viewModel.updateAmountWithResult(newValue) {
                    input = viewModel.formattedAmount
                }
            }
        }
        .padding()
    }
}

private extension FormattableAmountTextField {
    enum Layout {
        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }
    }
}
