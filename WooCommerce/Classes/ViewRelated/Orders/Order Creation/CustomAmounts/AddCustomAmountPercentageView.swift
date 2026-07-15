import SwiftUI

struct AddCustomAmountPercentageView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountPercentageViewModel
    private let isFocused: Binding<Bool>

    init(viewModel: AddCustomAmountPercentageViewModel, isFocused: Binding<Bool>? = nil) {
        self.viewModel = viewModel
        self.isFocused = isFocused ?? Binding(
            get: { viewModel.isFocused },
            set: { viewModel.isFocused = $0 }
        )
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
        @State private var focusRequestID = 0
        @Binding var text: String
        @Binding var isFocused: Bool
        var onChangeText: (String) -> (Void)

        var body: some View {
            ZStack {
                FocusableHiddenInputTextField(text: $text,
                                              isFocused: $isFocused,
                                              focusRequestID: focusRequestID,
                                              keyboardType: .decimalPad)
                    .onChange(of: text) {
                        onChangeText(text)
                    }
                    .frame(maxWidth: .infinity)

                Text(text + "%")
                    .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(text.isEmpty ? Color(.textSubtle) : Color(.text))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .if(isFocused, transform: { field in
                        field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
                    })
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: requestFocus)
            .fixedSize(horizontal: false, vertical: true)
            .restoresInputFocus(when: isFocused, restoreFocus: restoreFocusIfNeeded)
        }

        private func requestFocus() {
            isFocused = true
            focusRequestID += 1
        }

        private func restoreFocusIfNeeded() {
            guard isFocused else { return }

            requestFocus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard isFocused else { return }
                focusRequestID += 1
            }
        }
    }
}
