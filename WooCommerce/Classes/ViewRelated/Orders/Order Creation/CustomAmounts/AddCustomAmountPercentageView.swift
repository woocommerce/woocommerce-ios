import SwiftUI

struct AddCustomAmountPercentageView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountPercentageViewModel

    var body: some View {
        Group {
            VStack(alignment: .leading) {
                LabeledContent {
                    Text(viewModel.baseAmountForPercentageString)
                        .font(.subheadline)
                        .foregroundColor(Color(.textSubtle))
                } label: {
                    Text(Localization.percentageInputTitle)
                        .font(.subheadline)
                        .foregroundColor(Color(.textSubtle))
                }

                PercentageInputField(text: $viewModel.percentage, onChangeText: viewModel.updatePercentageCalculatedAmount)
            }

            LabeledContent {
                Text(viewModel.percentageCalculatedAmount)
                    .font(.subheadline)
                    .foregroundColor(Color(.textSubtle))
            } label: {
                Text(Localization.amountTitle)
                    .font(.subheadline)
                    .foregroundColor(Color(.textSubtle))
            }
        }
    }
}

private extension AddCustomAmountPercentageView {
    enum Layout {
        static func percentageFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
    }
}

private extension AddCustomAmountPercentageView {
    enum Localization {
        static let amountTitle = NSLocalizedString("addCustomAmountPercentageView.amount.title",
                                                   value: "Amount",
                                                   comment: "Title above the amount field on the add custom amount view in orders.")

        static let percentageInputTitle = NSLocalizedString("addCustomAmountPercentageView.percentageTextField.title",
                                                            value: "Enter percentage of order total",
                                                            comment: "Title for entering an custom amount through a percentage")
    }
}

private extension AddCustomAmountPercentageView {
    struct PercentageInputField: View {
        @ScaledMetric private var scale: CGFloat = 1.0
        @FocusState private var focusPercentageInput: Bool
        @Binding var text: String
        var onChangeText: (String) -> (Void)

        var body: some View {
            ZStack {
                TextField("",
                          text: $text,
                          prompt: Text("0").foregroundColor(Color(.textSubtle))
                )
                .onChange(of: text) {
                    onChangeText(text)
                }
                .focused()
                .focused($focusPercentageInput)
                .keyboardType(.decimalPad)
                .environment(\.layoutDirection, .leftToRight)
                .opacity(0)

                Text((text + "%").leftToRightIsolatedNumericRuns)
                    .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(text.isEmpty ? Color(.textSubtle) : Color(.text))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .if(focusPercentageInput, transform: { field in
                        field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
                    })
                    .onTapGesture {
                        focusPercentageInput = true
                    }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
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
