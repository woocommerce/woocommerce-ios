import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @ObservedObject private(set) var viewModel = AddCustomAmountViewModel()

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 8) {

                Spacer()

                // Instructions Label
                Text("Amount")
                    .font(.title3)
                    .foregroundColor(Color(.textSubtle))

                FormattableAmountTextField(formattedAmount: viewModel.formattedAmount, amountTextColor: viewModel.amountTextColor, amount: $viewModel.amount)

                Text("Name")
                    .font(.title3)
                    .foregroundColor(Color(.textSubtle))

                TextField("Custom Amount", text: $viewModel.name)
                    .secondaryTitleStyle()
                    .foregroundColor(Color(.textSubtle))
                    .multilineTextAlignment(.center)

                Spacer()

                Button("Add Custom Amount") {
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.loading))
                .disabled(viewModel.shouldDisableDoneButton)
            }
            .padding()
            .navigationTitle("Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                Text("Cancel")
            })
        }

        .wooNavigationBarStyle()
    }
}

private extension AddCustomAmountView {
    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
    }
}
