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
                    AccountSummaryItem(title: Localization.availableFunds, amount: viewModel.availableBalance)
                    AccountSummaryItem(title: Localization.pendingFunds, amount: viewModel.pendingBalance)
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
                    Text(viewModel.balanceTypeHint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    Divider()
                }
            }

            if isExpanded {
                Text(Localization.lastDepositHeader.localizedUppercase)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.flexible(maximum: 60), alignment: .leading),
                                    GridItem(alignment: .leading),
                                    GridItem(.flexible(minimum: 100), alignment: .leading),
                                    GridItem(alignment: .trailing)],
                          spacing: 16) {
                    Text(Localization.nextDepositRowTitle)
                    Text(viewModel.nextDepositDate)
                    WooPaymentsDepositsBadge(status: viewModel.nextDepositStatus)
                    Text(viewModel.nextDepositAmount)

                    Text(Localization.lastDepositRowTitle)
                        .foregroundColor(.secondary)
                    Text(viewModel.lastDepositDate)
                        .foregroundColor(.secondary)
                    WooPaymentsDepositsBadge(status: viewModel.lastDepositStatus)
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

struct WooPaymentsDepositsBadge: View {
    let status: WooPaymentsDepositStatus

    var body: some View {
        Text(status.localizedName)
            .foregroundColor(status.textColor)
            .padding(Layout.padding)
            .background(RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(status.backgroundColor))
    }
}

private extension WooPaymentsDepositsBadge {
    enum Layout {
        static let padding: CGFloat = 8.0
        static let cornerRadius: CGFloat = 8.0
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
        static let lastDepositHeader = NSLocalizedString(
            "Last Deposit",
            comment: "Section header for the last deposit in the WooPayments Deposits overview")
        static let nextDepositRowTitle = NSLocalizedString(
            "Next",
            comment: "Row title for the next deposit in the WooPayments Deposits overview")
        static let lastDepositRowTitle = NSLocalizedString(
            "deposits.currency.overview.depositTable.last.title",
            value: "Last",
            comment: "Row title for the last (previous) deposit in the WooPayments Deposits overview")
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
            pendingDepositDays: 2,
            nextDeposit: WooPaymentsDepositsOverviewByCurrency.NextDeposit(
                amount: 250.0,
                date: Date(),
                status: .pending
            ),
            lastDeposit: WooPaymentsDepositsOverviewByCurrency.LastDeposit(
                amount: 500.0,
                date: Date(),
                status: .inTransit
            ),
            availableBalance: 1500.0
        )

        let viewModel = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData)

        return WooPaymentsDepositsCurrencyOverviewView(viewModel: viewModel,
                                                       isExpanded: .constant(true))
        .previewLayout(.sizeThatFits)
    }
}
