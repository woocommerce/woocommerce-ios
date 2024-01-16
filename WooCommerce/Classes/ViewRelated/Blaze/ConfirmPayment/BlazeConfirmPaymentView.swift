import SwiftUI

/// View to confirm the payment method before creating a Blaze campaign.
struct BlazeConfirmPaymentView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    @ObservedObject private var viewModel: BlazeConfirmPaymentViewModel

    init(viewModel: BlazeConfirmPaymentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.contentPadding) {
                Text("Payment totals")
                    .bold()
                    .bodyStyle()

                HStack {
                    Text("Blaze campaign")
                        .bodyStyle()

                    Spacer()

                    Text("$35")
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Text("Total")
                        .bold()

                    Spacer()

                    Text("$35 USD")
                        .bold()
                }
                .bodyStyle()

                Divider()

                HStack {
                    Image("card-brand-visa")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35 * scale)

                    VStack(alignment: .leading) {
                        Text("Visa")
                            .bodyStyle()
                        Text("Card ending with 2222")
                            .foregroundColor(.secondary)
                            .captionStyle()
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .secondaryBodyStyle()
                }
            }
            .padding(Layout.contentPadding)
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Layout.contentPadding) {
                Divider()
                Button("Submit Campaign") {
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("By clicking \"Submit campaign\" you agree to the Terms of Service and " +
                     "Advertising Policy, and authorize your payment method to be charged for " +
                     "the budget and duration you chose. Learn more about how budgets and payments for Promoted Posts work.")
                .foregroundColor(.secondary)
                .captionStyle()
            }
            .padding(Layout.contentPadding)
            .background(Color(.systemBackground))
        }
    }
}

private extension BlazeConfirmPaymentView {

    enum Layout {
        static let contentPadding: CGFloat = 16
    }
}

#Preview {
    BlazeConfirmPaymentView(viewModel: BlazeConfirmPaymentViewModel())
}
