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
    }
}

private extension AddCustomAmountView {
    enum Localization {
        static let amountTitle = NSLocalizedString("Amount", comment: "Title above the amount field on the add custom amount view in orders.")
        static let nameTitle = NSLocalizedString("Name", comment: "Title above the name field on the add custom amount view in orders.")
        static let navigationTitle = NSLocalizedString("Custom Amount", comment: "Navigation title on the add custom amount view in orders.")
        static let navigationCancelButtonTitle = NSLocalizedString("Cancel",
                                                                comment: "Cancel button title on the navigation bar on the add custom amount view in orders.")
    }
}
