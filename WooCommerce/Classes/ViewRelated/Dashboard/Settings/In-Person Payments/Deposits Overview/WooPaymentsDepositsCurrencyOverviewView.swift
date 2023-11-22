import SwiftUI
import Yosemite

@available(iOS 16.0, *)
struct WooPaymentsDepositsCurrencyOverviewView: View {
    @ObservedObject var viewModel: WooPaymentsDepositsCurrencyOverviewViewModel

    @Binding var isExpanded: Bool

    @State private var showDepositSummaryInfo: Bool = false

    init(viewModel: WooPaymentsDepositsCurrencyOverviewViewModel,
         isExpanded: Binding<Bool>) {
        self.viewModel = viewModel
        self._isExpanded = isExpanded
    }

    var body: some View {
        VStack {
            Grid(alignment: .leading) {
                GridRow {
                    AccountSummaryItem(title: Localization.availableFunds,
                                       amount: viewModel.availableBalance,
                                       footer: "")
                    AccountSummaryItem(title: Localization.pendingFunds,
                                       amount: viewModel.pendingBalance,
                                       footer: viewModel.pendingFundsDepositsSummary)
                    isExpanded ? Image(systemName: "chevron.up")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(Text(Localization.hideDepositDetailAccessibilityLabel)) :
                    Image(systemName: "chevron.down")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(Text(Localization.showDepositDetailAccessibilityLabel))

                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                    viewModel.expandTapped(expanded: isExpanded)
                }

                if isExpanded {
                    Divider()

                    HStack(alignment: .top) {
                        Image(systemName: "calendar")
                            .accessibilityHidden(true)
                        Text(viewModel.balanceTypeHint)
                            .font(.footnote)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                }
            }

            if isExpanded {
                Text(Localization.depositsHeader.localizedUppercase)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible(maximum: 70), alignment: .leading),
                                    GridItem(alignment: .leading),
                                    GridItem(alignment: .trailing)],
                          spacing: 16) {
                    Text(Localization.nextDepositRowTitle)
                    Text(viewModel.nextDepositDate)
                    Text(viewModel.nextDepositAmount)

                    Text(Localization.paidDepositRowTitle)
                        .foregroundColor(.withColorStudio(name: .green, shade: .shade50))
                    Text(viewModel.lastDepositDate)
                        .foregroundColor(.secondary)
                    Text(viewModel.lastDepositAmount)
                        .foregroundColor(.secondary)
                }
                Divider()

                HStack(alignment: .top) {
                    Image(systemName: "building.columns")
                        .accessibilityHidden(true)
                    Text(viewModel.depositScheduleHint)
                        .font(.footnote)
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    showDepositSummaryInfo = true
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
                .padding(.bottom)
            }
        }
        .safariSheet(isPresented: $showDepositSummaryInfo, url: WooConstants.URLs.wooPaymentsDepositSchedule.asURL())
        .animation(.easeOut, value: isExpanded)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}

struct AccountSummaryItem: View {
    let title: String
    let amount: String
    let footer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)

            Text(amount)
                .font(.title2)
                .fontWeight(.bold)

            Text(footer ?? "")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 16.0, *)
private extension WooPaymentsDepositsCurrencyOverviewView {
    enum Localization {
        static let availableFunds = NSLocalizedString(
            "Available funds",
            comment: "Title for available funds overview in WooPayments Deposits view. " +
            "This shows the balance which can be paid out.")
        static let pendingFunds = NSLocalizedString(
            "Pending funds",
            comment: "Title for pending funds overview in WooPayments Deposits view. " +
            "This shows the balance which will be made available for pay out later.")
        static let depositsHeader = NSLocalizedString(
            "Deposits",
            comment: "Section header for the deposits list in the WooPayments Deposits overview")
        static let nextDepositRowTitle = NSLocalizedString(
            "Next",
            comment: "Row title for the next deposit in the WooPayments Deposits overview")
        static let paidDepositRowTitle = NSLocalizedString(
            "Paid",
            comment: "Row title for the last paid deposit in the WooPayments Deposits overview")
        static let learnMoreButtonText = NSLocalizedString(
            "Learn more about when you'll receive your funds",
            comment: "Button text to view more about payment schedules on the WooPayments Deposits View.")
        static let showDepositDetailAccessibilityLabel = NSLocalizedString(
            "deposits.currency.overview.accessibility.show",
            value: "Show deposit details",
            comment: "Accessibility label for the expand chevron on the Deposit summary")
        static let hideDepositDetailAccessibilityLabel = NSLocalizedString(
            "deposits.currency.overview.accessibility.hide",
            value: "Hide deposit details",
            comment: "Accessibility label for the collapse chevron on the Deposit summary")
    }
}

@available(iOS 16.0, *)
struct WooPaymentsDepositsCurrencyOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let overviewData = WooPaymentsDepositsOverviewByCurrency(
            currency: .GBP,
            automaticDeposits: true,
            depositInterval: .daily,
            pendingBalanceAmount: 1000.0,
            pendingDepositsCount: 5,
            pendingDepositDays: 2,
            nextDeposit: WooPaymentsDepositsOverviewByCurrency.NextDeposit(
                amount: 250.0,
                date: Date(),
                status: .pending
            ),
            lastDeposit: WooPaymentsDepositsOverviewByCurrency.LastDeposit(
                amount: 500.0,
                date: Date()
            ),
            availableBalance: 1500.0
        )

        let viewModel = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData)

        return WooPaymentsDepositsCurrencyOverviewView(viewModel: viewModel,
                                                       isExpanded: .constant(true))
        .previewLayout(.sizeThatFits)
    }
}
