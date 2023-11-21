import SwiftUI

struct AddCustomAmountPercentageView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountPercentageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.mainVerticalSpacing) {
            HStack() {
                Text(Localization.percentageInputTitle)
                    .font(.subheadline)
                    .foregroundColor(Color(.textSubtle))

                Spacer()

                Text("(\(viewModel.baseAmountForPercentageString))")
                    .font(.subheadline)
                    .foregroundColor(Color(.textSubtle))
            }

            PercentageInputField(text: $viewModel.percentage)

            Divider()
                .padding(.bottom, Layout.mainVerticalSpacing)

            HStack() {
                Text(Localization.amountTitle)
                    .font(.subheadline)
                    .foregroundColor(Color(.textSubtle))

                Spacer()

                Text(viewModel.percentageCalculatedAmount)
                    .font(.subheadline)
                    .foregroundColor(Color(.textSubtle))
            }
        }
    }
}

private extension AddCustomAmountPercentageView {
    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
        static let textFieldMaxWidth: CGFloat = 200
        static func percentageFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
    }
}

private extension AddCustomAmountPercentageView {
    enum Localization {
        static let amountTitle = NSLocalizedString("Amount", comment: "Title above the amount field on the add custom amount view in orders.")

        static let percentageInputTitle = NSLocalizedString("addCustomAmountView.percentageTextField.title",
                                                            value: "Enter percentage of order total",
                                                            comment: "Title for entering an custom amount through a percentage")
        static let percentageInputPlaceholder = NSLocalizedString("addCustomAmountView.percentageTextField.placeholder",
                                                                  value: "Enter percentage",
                                                                  comment: "Placeholder for entering an custom amount through a percentage")
    }
}

private extension AddCustomAmountPercentageView {
    struct PercentageInputField: View {
        @ScaledMetric private var scale: CGFloat = 1.0
        @Binding var text: String
        @FocusState var focused: Bool?

        var body: some View {
            HStack(spacing: 0) {
                TextField("",
                          text: $text,
                          prompt: Text("0").foregroundColor(Color(.textSubtle))
                )
                .focused($focused, equals: true)
                .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                .keyboardType(.decimalPad)
                .frame(maxWidth: Layout.textFieldMaxWidth)
                .fixedSize()
                .onAppear {
                  DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.focused = true
                  }
                }

                Text("%")
                    .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                    .foregroundColor(text.isEmpty ? Color(.textSubtle) : Color(.text))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
