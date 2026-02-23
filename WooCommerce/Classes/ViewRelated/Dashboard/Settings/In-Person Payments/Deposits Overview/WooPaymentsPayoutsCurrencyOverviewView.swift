import SwiftUI
import Yosemite

struct WooPaymentsPayoutsCurrencyOverviewView: View {
    @ObservedObject var viewModel: WooPaymentsPayoutsCurrencyOverviewViewModel

    @Binding var isExpanded: Bool

    @State private var showPayoutSummaryInfo: Bool = false

    init(viewModel: WooPaymentsPayoutsCurrencyOverviewViewModel,
         isExpanded: Binding<Bool>) {
        self.viewModel = viewModel
        self._isExpanded = isExpanded
    }

    var body: some View {
        VStack {
            Grid(alignment: .leading) {
                GridRow {
                    AccountSummaryItem(title: Localization.availableFunds, amount: viewModel.availableBalance)
                    AccountSummaryItem(title: Localization.pendingFunds, amount: viewModel.pendingBalance)
                    isExpanded ? Image(systemName: "chevron.up")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(Text(Localization.hidePayoutDetailAccessibilityLabel)) :
                    Image(systemName: "chevron.down")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(Text(Localization.showPayoutDetailAccessibilityLabel))

                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                    viewModel.expandTapped(expanded: isExpanded)
                }

                if isExpanded {
                    Text(viewModel.balanceTypeHint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, Layout.padding)
                    Divider()
                }
            }

            if isExpanded {
                Text(Localization.lastPayoutHeader.localizedUppercase)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Layout.padding)
                    .accessibilityAddTraits(.isHeader)
                AdaptiveStack(horizontalAlignment: .leading, spacing: Layout.elementSpacing) {
                    HStack {
                        Image(systemName: "calendar")
                            .accessibilityHidden(true)
                        Text(viewModel.lastPayoutDate)
                            .foregroundColor(.primary)
                    }
                    WooPaymentsPayoutsBadge(status: viewModel.lastPayoutStatus)
                    Spacer()
                    Text(viewModel.lastPayoutAmount)
                        .foregroundColor(.primary)
                }

                HStack(alignment: .top) {
                    Text(viewModel.payoutScheduleHint)
                        .font(.footnote)
                }
                .foregroundColor(.secondary)
                .padding(.vertical, Layout.padding)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                Button {
                    viewModel.learnMoreTapped()
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .accessibilityHidden(true)
                        Text(Localization.learnMoreButtonText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.top)
                .padding(.bottom)
            }
        }
        .safariSheet(url: $viewModel.showWebviewURL)
        .animation(.easeOut, value: isExpanded)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}

struct AccountSummaryItem: View {
    let title: String
    let amount: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .accessibilityAddTraits(.isHeader)

            Text(amount)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .accessibilityElement(children: .combine)
    }
}

struct WooPaymentsPayoutsBadge: View {
    let status: WooPaymentsPayoutStatus

    var body: some View {
        Text(status.localizedName)
            .foregroundColor(status.textColor)
            .padding(Layout.padding)
            .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(status.backgroundColor))
    }
}

private extension WooPaymentsPayoutsBadge {
    enum Layout {
        static let padding: CGFloat = 8.0
        static let cornerRadius: CGFloat = 8.0
    }
}

private extension WooPaymentsPayoutsCurrencyOverviewView {
    enum Layout {
        static let padding: CGFloat = 8.0
        static let elementSpacing: CGFloat = 16.0
    }
}

private extension WooPaymentsPayoutsCurrencyOverviewView {
    enum Localization {
        static let availableFunds = NSLocalizedString(
            "payouts.currency.overview.availableFunds",
            value: "Available funds",
            comment: "Title for available funds overview in WooPayments Payouts view. " +
            "This shows the balance which can be paid out.")
        static let pendingFunds = NSLocalizedString(
            "payouts.currency.overview.pendingFunds",
            value: "Pending funds",
            comment: "Title for pending funds overview in WooPayments Payouts view. " +
            "This shows the balance which will be made available for pay out later.")
        static let lastPayoutHeader = NSLocalizedString(
            "payouts.currency.overview.lastPayout",
            value: "Last Payout",
            comment: "Section header for the last payout in the WooPayments Payouts overview")
        static let learnMoreButtonText = NSLocalizedString(
            "payouts.currency.overview.learnMore",
            value: "Learn more about when you'll receive your funds",
            comment: "Button text to view more about payment schedules on the WooPayments Payouts View.")
        static let showPayoutDetailAccessibilityLabel = NSLocalizedString(
            "payouts.currency.overview.accessibility.show",
            value: "Show payout details",
            comment: "Accessibility label for the expand chevron on the Payout summary")
        static let hidePayoutDetailAccessibilityLabel = NSLocalizedString(
            "payouts.currency.overview.accessibility.hide",
            value: "Hide payout details",
            comment: "Accessibility label for the collapse chevron on the Payout summary")
    }
}

struct WooPaymentsPayoutsCurrencyOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let overviewData = WooPaymentsPayoutsOverviewByCurrency(
            currency: .GBP,
            automaticPayouts: true,
            payoutInterval: .daily,
            pendingBalanceAmount: 1000.0,
            pendingPayoutDays: 2,
            lastPayout: WooPaymentsPayoutsOverviewByCurrency.LastPayout(
                amount: 500.0,
                date: Date(),
                status: .inTransit
            ),
            availableBalance: 1500.0
        )

        let viewModel = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: overviewData)

        return WooPaymentsPayoutsCurrencyOverviewView(viewModel: viewModel,
                                                       isExpanded: .constant(true))
        .previewLayout(.sizeThatFits)
    }
}
