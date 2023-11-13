import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .center, spacing: Layout.mainVerticalSpacing) {
                        Spacer()

                        Text(Localization.amountTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))

                        FormattableAmountTextField(viewModel: viewModel.formattableAmountTextFieldViewModel)

                        VStack(alignment: .leading, spacing: Layout.mainVerticalSpacing) {
                            Text(Localization.percentageInputTitle + " " + viewModel.baseAmountForPercentageString)
                                .font(.subheadline)
                                .foregroundColor(Color(.textSubtle))

                            HStack(spacing: Layout.inputFieldVerticalSpacing) {
                                InputField(placeholder: Localization.percentageInputPlaceholder,
                                           text: $viewModel.percentage)

                                Text("%")
                                    .font(.title3)
                                    .foregroundColor(Color(.textSubtle))
                            }
                        }
                        .padding(.bottom, Layout.mainVerticalSpacing)
                        .renderedIf(viewModel.showPercentageInput)

                        Text(Localization.nameTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))

                        TextField(viewModel.customAmountPlaceholder, text: $viewModel.name)
                            .secondaryTitleStyle()
                            .foregroundColor(Color(.textSubtle))
                            .multilineTextAlignment(.center)

                        Spacer()

                        Button(viewModel.doneButtonTitle) {
                            viewModel.doneButtonPressed()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.shouldDisableDoneButton)
                        .accessibilityIdentifier(AccessibilityIdentifiers.addCustomAmountButton)
                    }
                    .padding()
                    .navigationTitle(Localization.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .frame(minHeight: geometry.size.height)
                    .navigationBarItems(leading: Button(action: {
                        dismiss()
                    }) {
                        Text(Localization.navigationCancelButtonTitle)
                    })
                }
                .frame(width: geometry.size.width)
            }
        }
        .wooNavigationBarStyle()
    }
}

private extension AddCustomAmountView {
    struct InputField: View {
        let placeholder: String
        @Binding var text: String

        var body: some View {
            TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .padding(EdgeInsets(top: 0, leading: Layout.inputFieldInnerVerticalPadding, bottom: 0, trailing: Layout.inputFieldInnerVerticalPadding))
            .frame(maxWidth: .infinity, minHeight: Layout.inputFieldHeight, maxHeight: Layout.inputFieldHeight)
            .overlay {
                RoundedRectangle(cornerRadius: Layout.frameCornerRadius)
                    .inset(by: Layout.inputFieldOverlayInset)
                    .stroke(Color(uiColor: .wooCommercePurple(.shade50)), lineWidth: Layout.borderLineWidth)
            }
            .cornerRadius(Layout.frameCornerRadius)
        }
    }
}

private extension AddCustomAmountView {
    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
        static let rowHeight: CGFloat = 44
        static let frameCornerRadius: CGFloat = 4
        static let borderLineWidth: CGFloat = 1
        static let inputFieldOverlayInset: CGFloat = 0.25
        static let inputFieldHeight: CGFloat = 44
        static let inputFieldInnerVerticalPadding: CGFloat = 8
        static let inputFieldVerticalSpacing: CGFloat = 8
    }
}

private extension AddCustomAmountView {
    enum Localization {
        static let amountTitle = NSLocalizedString("Amount", comment: "Title above the amount field on the add custom amount view in orders.")
        static let nameTitle = NSLocalizedString("Name", comment: "Title above the name field on the add custom amount view in orders.")
        static let navigationTitle = NSLocalizedString("Custom Amount", comment: "Navigation title on the add custom amount view in orders.")
        static let navigationCancelButtonTitle = NSLocalizedString("Cancel",
                                                                comment: "Cancel button title on the navigation bar on the add custom amount view in orders.")
        static let percentageInputTitle = NSLocalizedString("addCustomAmountView.percentageTextField.title",
                                                             value: "Or enter percentage of the order total",
                                                             comment: "Title for entering an custom amount through a percentage")
        static let percentageInputPlaceholder = NSLocalizedString("addCustomAmountView.percentageTextField.placeholder",
                                                             value: "Enter percentage",
                                                             comment: "Placeholder for entering an custom amount through a percentage")
    }

    enum AccessibilityIdentifiers {
        static let addCustomAmountButton = "order-add-custom-amount-view-add-custom-amount-button"
    }
}
