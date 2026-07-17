import SwiftUI
import WooFoundation

struct AddCustomAmountPercentageView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountPercentageViewModel
    private let isFocused: Binding<Bool>

    init(viewModel: AddCustomAmountPercentageViewModel, isFocused: Binding<Bool>) {
        self.viewModel = viewModel
        self.isFocused = isFocused
    }

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

                PercentageInputField(text: $viewModel.percentage,
                                     isFocused: isFocused,
                                     onChangeText: viewModel.updatePercentageCalculatedAmount)
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
        @FocusState private var fieldIsFocused: Bool
        @Binding var text: String
        @Binding var isFocused: Bool
        var onChangeText: (String) -> Void

        var body: some View {
            TextField("", text: percentageText, prompt: Text("%"))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .focused($fieldIsFocused)
                .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(text.isEmpty ? Color(.textSubtle) : Color(.text))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .if(isFocused, transform: { field in
                    field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
                })
                .fixedSize(horizontal: false, vertical: true)
                .onAppear(perform: syncFocusFromBinding)
                .onChange(of: fieldIsFocused) { _, fieldIsFocused in
                    guard isFocused != fieldIsFocused else { return }
                    isFocused = fieldIsFocused
                }
                .onChange(of: isFocused) { _, shouldFocus in
                    guard fieldIsFocused != shouldFocus else { return }
                    fieldIsFocused = shouldFocus
                }
        }

        private var percentageText: Binding<String> {
            Binding(
                get: {
                    text.isEmpty ? "" : text + "%"
                },
                set: { newValue in
                    let previousText = text
                    let previousFormattedText = previousText.isEmpty ? "" : previousText + "%"
                    var updatedText = newValue.replacingOccurrences(of: "%", with: "")
                    if newValue.count < previousFormattedText.count,
                       updatedText == previousText,
                       previousText.isNotEmpty,
                       newValue != previousFormattedText {
                        updatedText = String(previousText.dropLast())
                    }

                    text = updatedText
                    onChangeText(updatedText)
                }
            )
        }

        private func syncFocusFromBinding() {
            fieldIsFocused = isFocused
        }
    }
}
