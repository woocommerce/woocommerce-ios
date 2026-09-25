import SwiftUI

struct POSCashSessionDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posCurrencyProvider) private var currencyProvider

    let session: POSCashSession
    let onBack: () -> Void

    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings, session: session) }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: horizontalSizeClass == .compact ?
                    String.localizedStringWithFormat(Localization.compactSessionNumber, String(session.id)) :
                    String.localizedStringWithFormat(Localization.sessionNumber, String(session.id)),
                backButtonConfiguration: .init(state: .enabled, action: onBack)
            )
            .environment(\.posHeaderBackButtonConfiguration, .init(state: .enabled, action: onBack))

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    HStack(alignment: .top, spacing: POSSpacing.small) {
                        dateCard(label: Localization.opened, date: session.openedAt, actor: session.openedBy)
                        if let closedAt = session.closedAt {
                            dateCard(label: Localization.closed, date: closedAt, actor: session.closedBy ?? session.openedBy)
                        }
                    }

                    POSInformationCard {
                        VStack(alignment: .leading, spacing: POSSpacing.medium) {
                            Text(Localization.drawerSummary)
                                .font(.posBodyMediumBold)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: POSSpacing.medium),
                                                     count: horizontalSizeClass == .compact ? 2 : 4),
                                      alignment: .leading, spacing: POSSpacing.medium) {
                                POSCashSessionMetricView(label: Localization.startingCash, amount: money.format(session.openingCash))
                                POSCashSessionMetricView(label: Localization.expectedCash, amount: money.format(session.expectedCash))
                                POSCashSessionMetricView(label: Localization.countedCash, amount: money.format(session.countedCash ?? 0))
                                POSCashSessionMetricView(label: Localization.difference, amount: money.formatSigned(session.difference ?? 0))
                            }

                            POSDivider()
                            summaryRow(Localization.cashSales, money.format(session.cashSales))
                            summaryRow(Localization.paidInOut, money.format(session.paidInOut))
                            summaryRow(Localization.cashRefunds, money.format(-session.cashRefunds))
                        }
                    }

                    POSCashSessionActivityView(session: session)
                }
                .padding(POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .accessibilityIdentifier("pos-cash-drawer-session-detail-view")
    }

    private func dateCard(label: String, date: Date, actor: String) -> some View {
        POSInformationCard {
            VStack(alignment: .leading, spacing: POSSpacing.small) {
                Text(label)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(.secondary)
                Text(date.formatted(date: .long, time: .shortened))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurface)
                Text(actor)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func summaryRow(_ label: String, _ amount: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(amount).foregroundStyle(Color.posOnSurface)
        }
        .font(.posBodyMediumRegular())
        .accessibilityElement(children: .combine)
    }
}

private extension POSCashSessionDetailView {
    enum Localization {
        static let sessionNumber = NSLocalizedString("pos.cashSession.detail.number", value: "Session #%1$@", comment: "Closed cash session title")
        static let compactSessionNumber = NSLocalizedString("pos.cashSession.detail.compactNumber", value: "#%1$@",
                                                        comment: "Closed cash session title on iPhone")
        static let opened = NSLocalizedString("pos.cashSession.detail.opened", value: "Opened", comment: "Session opening information")
        static let closed = NSLocalizedString("pos.cashSession.detail.closed", value: "Closed", comment: "Session closing information")
        static let drawerSummary = NSLocalizedString("pos.cashSession.detail.summary", value: "Drawer summary", comment: "Cash drawer summary title")
        static let startingCash = NSLocalizedString("pos.cashSession.detail.startingCash", value: "Starting cash", comment: "Opening float")
        static let expectedCash = NSLocalizedString("pos.cashSession.detail.expected", value: "Expected in drawer", comment: "Expected closing cash")
        static let countedCash = NSLocalizedString("pos.cashSession.detail.counted", value: "Cash in drawer", comment: "Counted closing cash")
        static let difference = NSLocalizedString("pos.cashSession.detail.difference", value: "Difference", comment: "Counted minus expected cash")
        static let cashSales = NSLocalizedString("pos.cashSession.detail.sales", value: "Cash sales", comment: "Cash sales total")
        static let paidInOut = NSLocalizedString("pos.cashSession.detail.paidInOut", value: "Paid in/out", comment: "Cash movements total")
        static let cashRefunds = NSLocalizedString("pos.cashSession.detail.refunds", value: "Cash refunds", comment: "Cash refunds total")
    }
}
