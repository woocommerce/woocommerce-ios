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
                Text(Localization.paymentTotals)
                    .bold()
                    .bodyStyle()

                HStack {
                    Text(Localization.blazeCampaign)
                        .bodyStyle()

                    Spacer()

                    Text("$35")
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Text(Localization.total)
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
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Layout.contentPadding) {
                Divider()
                Button(Localization.submitButton) {
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

    enum Localization {
        static let title = NSLocalizedString(
            "blazeConfirmPaymentView.title",
            value: "Payment",
            comment: "Title of the Payment view in the Blaze campaign creation flow"
        )
        static let submitButton = NSLocalizedString(
            "blazeConfirmPaymentView.submitButton",
            value: "Submit Campaign",
            comment: "Action button in the Payment view in the Blaze campaign creation flow"
        )
        static let paymentTotals = NSLocalizedString(
            "blazeConfirmPaymentView.paymentTotals",
            value: "Payment totals",
            comment: "Section title in the Payment view in the Blaze campaign creation flow"
        )
        static let blazeCampaign = NSLocalizedString(
            "blazeConfirmPaymentView.blazeCampaign",
            value: "Blaze campaign",
            comment: "Item to be charged in the Payment view in the Blaze campaign creation flow"
        )
        static let total = NSLocalizedString(
            "blazeConfirmPaymentView.total",
            value: "Total",
            comment: "Title of the total amount to be charged in the Payment view in the Blaze campaign creation flow"
        )
    }
}

#Preview {
    BlazeConfirmPaymentView(viewModel: BlazeConfirmPaymentViewModel())
}
