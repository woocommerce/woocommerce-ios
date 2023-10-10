import SwiftUI

/// This numeric Text Field updates the user input to show the formatted amount
///
struct FormattableAmountTextField: View {
    let formattedAmount: String
    let amountTextColor: UIColor

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding var amount: String
    @State var focusAmountInput: Bool = true

    var body: some View {
        ZStack(alignment: .center) {
            // Hidden input text field
            BindableTextfield("", text: $amount, focus: $focusAmountInput)
                .keyboardType(.decimalPad)
                .opacity(0)

            // Visible & formatted label
            Text(formattedAmount)
                .font(.system(size: Layout.amountFontSize(scale: scale), weight: .bold))
                .foregroundColor(Color(amountTextColor))
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
        static func amountFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
    }
}
