import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.mainVerticalSpacing) {

                        if let formattableAmountTextFieldViewModel = viewModel.formattableAmountTextFieldViewModel {
                            Group {
                                Text(Localization.amountTitle)
                                    .font(.title3)
                                    .foregroundColor(Color(.textSubtle))

                                FormattableAmountTextField(viewModel: formattableAmountTextFieldViewModel)

                                Divider()
                                    .padding(.bottom, Layout.mainVerticalSpacing)
                            }
                        }
//
                        if let percentageViewModel = viewModel.percentageViewModel {
                            AddCustomAmountPercentageView(viewModel: percentageViewModel)
                                .padding(.bottom, Layout.mainVerticalSpacing)
                        }


                        Toggle(Localization.chargeTaxesToggleTitle, isOn: $viewModel.isTaxable)
                            .font(.title3)
                            .padding(.bottom, Layout.mainVerticalSpacing)

                        Text(Localization.nameTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))

                        TextField(viewModel.customAmountPlaceholder, text: $viewModel.name)
                            .secondaryTitleStyle()
                            .foregroundColor(Color(.textSubtle))

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
    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
        static func percentageFontSize(scale: CGFloat) -> CGFloat {
            56 * scale
        }
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
                                                             value: "Enter percentage of order total",
                                                             comment: "Title for entering an custom amount through a percentage")
        static let percentageInputPlaceholder = NSLocalizedString("addCustomAmountView.percentageTextField.placeholder",
                                                             value: "Enter percentage",
                                                             comment: "Placeholder for entering an custom amount through a percentage")
        static let chargeTaxesToggleTitle = NSLocalizedString("addCustomAmountView.chargeTaxesToggle.title",
                                                             value: "Charge Taxes",
                                                             comment: "Title for the charge taxes toggle in the custom amounts screen.")
    }

    enum AccessibilityIdentifiers {
        static let addCustomAmountButton = "order-add-custom-amount-view-add-custom-amount-button"
    }
}

struct AddCustomAmountPercentageView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountPercentageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .padding(.bottom, 8)

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

    enum AccessibilityIdentifiers {
        static let addCustomAmountButton = "order-add-custom-amount-view-add-custom-amount-button"
    }
}

private extension AddCustomAmountPercentageView {
    struct PercentageInputField: View {
        @ScaledMetric private var scale: CGFloat = 1.0
        @Binding var text: String

        var body: some View {
            HStack(spacing: 0) {
                TextField("",
                          text: $text,
                          prompt: Text("0").foregroundColor(Color(.textSubtle))
                )
                .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize()

                Text("%")
                    .font(.system(size: Layout.percentageFontSize(scale: scale), weight: .bold))
                    .foregroundColor(text.isEmpty ? Color(.textSubtle) : Color(.text))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
