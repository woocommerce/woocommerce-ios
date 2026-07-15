import SwiftUI

/// This numeric Text Field updates the user input to show the formatted amount
///
struct FormattableAmountTextField: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var focusAmountInput: Bool

    @ObservedObject private var viewModel: FormattableAmountTextFieldViewModel
    private let style: Style

    init(viewModel: FormattableAmountTextFieldViewModel, style: Style = .default) {
        self.viewModel = viewModel
        self.style = style
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Hidden input text field
            TextField("", text: $viewModel.textFieldAmountText)
                .onChange(of: viewModel.textFieldAmountText) { _, newValue in
                    viewModel.updateAmount(newValue)
                }
                .focused()
                .focused($focusAmountInput)
                .keyboardType(viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
                .environment(\.layoutDirection, .leftToRight)
                .opacity(0)

            Text(viewModel.formattedAmount.leftToRightIsolatedNumericRuns)
                .font(style.font ?? .system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
                .foregroundColor(Color(viewModel.amountTextColor))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: style.textAlignment)
                .padding(5)
                .if(focusAmountInput && style.showsBorder, transform: { field in
                    field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
                })
                .onTapGesture {
                    focusAmountInput = true
                }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension FormattableAmountTextField {
    struct Style: Equatable {
        let showsBorder: Bool
        let textAlignment: Alignment
        /// Optional font to use for the amount text. If nil, a default system font will be used.
        let font: Font?

        static let `default` = Style(
            showsBorder: true,
            textAlignment: .leading,
            font: nil
        )
    }
}

private extension String {
    var leftToRightIsolatedNumericRuns: String {
        var result = ""
        var currentRun = ""
        let characters = Array(self)

        for (index, character) in characters.enumerated() {
            if character.isNumber || shouldTreatAsNumericSeparator(character, at: index, in: characters) {
                currentRun.append(character)
            } else {
                result.appendLeftToRightIsolatedRunIfNeeded(currentRun)
                currentRun = ""
                result.append(character)
            }
        }

        result.appendLeftToRightIsolatedRunIfNeeded(currentRun)
        return result
    }

    private func shouldTreatAsNumericSeparator(_ character: Character, at index: Int, in characters: [Character]) -> Bool {
        guard character == "." || character == "," || character == "-" else {
            return false
        }

        let previousCharacterIsNumber = index > 0 && characters[index - 1].isNumber
        let nextCharacterIsNumber = index < characters.count - 1 && characters[index + 1].isNumber

        return previousCharacterIsNumber || nextCharacterIsNumber
    }

    mutating func appendLeftToRightIsolatedRunIfNeeded(_ run: String) {
        guard run.isNotEmpty else {
            return
        }

        append("\u{2066}\(run)\u{2069}")
    }
}

private extension FormattableAmountTextField {
    enum Layout {
        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }
    }
}

#Preview {
    let viewModel = FormattableAmountTextFieldViewModel(size: .extraLarge,
                                                        locale: .current,
                                                        storeCurrencySettings: .init(),
                                                        allowNegativeNumber: false)
    VStack {
        Text("Default style")
        FormattableAmountTextField(viewModel: viewModel, style: .default)
    }
    VStack {
        Text("Other style")
        FormattableAmountTextField(viewModel: viewModel, style: .init(showsBorder: false, textAlignment: .center, font: .title2))
    }
}
