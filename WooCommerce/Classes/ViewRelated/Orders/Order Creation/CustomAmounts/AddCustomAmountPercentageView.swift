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
                                                   comment: "A label that appears above the amount input field in the add custom amount view during order creation, indicating where users enter monetary values.")

        static let percentageInputTitle = NSLocalizedString("addCustomAmountPercentageView.percentageTextField.title",
                                                            value: "Enter percentage of order total",
                                                            comment: "This text appears as a title or label above a percentage input field in the custom amount creation view when adding custom amounts to orders, guiding users to enter a percentage value that will be calculated against the order total.")
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
                .opacity(0)

                Text(text + "%")
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
