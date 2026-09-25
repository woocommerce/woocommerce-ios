import SwiftUI

struct POSCurrentCashSessionView: View {
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @State private var entryAction: POSCashSessionEntryView.Action?

    let controller: POSCashSessionController
    let onClosed: (Int64) -> Void

    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings, session: controller.currentSession) }

    var body: some View {
        if let session = controller.currentSession {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(title: Localization.title,
                                  subtitle: String.localizedStringWithFormat(Localization.sessionNumber, String(session.id)),
                                  trailingContent: {
                    HStack(spacing: POSSpacing.small) {
                        Button(Localization.closeButton) { entryAction = .close }
                            .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .primary, isLoading: false))
                        Menu {
                            Button(Localization.payIn) { entryAction = .payIn }
                            Button(Localization.payOut) { entryAction = .payOut }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.posBodyLargeBold)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                .foregroundColor(.posOnSurface)
                                .padding(POSPadding.small)
                        }
                        .menuIndicator(.hidden)
                        .accessibilityLabel(Localization.recordMovement)
                    }
                })

                ScrollView {
                    VStack(alignment: .leading, spacing: POSSpacing.medium) {
                        POSInformationCard {
                            POSCashSessionMetricView(label: Localization.expectedCash, amount: money.format(session.expectedCash))
                        }

                        HStack(alignment: .top, spacing: POSSpacing.small) {
                            POSInformationCard {
                                POSCashSessionMetricView(label: Localization.cashSales, amount: money.format(session.cashSales))
                            }
                            POSInformationCard {
                                POSCashSessionMetricView(label: Localization.paidInOut, amount: money.format(session.paidInOut))
                            }
                            POSInformationCard {
                                POSCashSessionMetricView(label: Localization.cashRefunds, amount: money.format(-session.cashRefunds))
                            }
                        }

                        POSCashSessionActivityView(session: session)
                    }
                    .padding(POSPadding.medium)
                }
            }
            .background(Color.posSurface)
            .posFullScreenCover(item: $entryAction) { action in
                POSCashSessionEntryView(action: action, controller: controller, onClosed: onClosed)
            }
            .accessibilityIdentifier("pos-cash-drawer-current-session-view")
        }
    }
}

struct POSCashSessionMetricView: View {
    let label: String
    let amount: String

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(label)
                .font(.posBodySmallRegular())
                .foregroundStyle(.secondary)
            Text(amount)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private extension POSCurrentCashSessionView {
    enum Localization {
        static let title = NSLocalizedString("pos.cashSession.current.title", value: "Current session", comment: "Current cash session title")
        static let sessionNumber = NSLocalizedString("pos.cashSession.current.number", value: "#%1$@", comment: "Cash session number")
        static let closeButton = NSLocalizedString("pos.cashSession.current.close", value: "Close session", comment: "Close current cash session")
        static let payIn = NSLocalizedString("pos.cashSession.current.payIn", value: "Pay in", comment: "Record cash added to drawer")
        static let payOut = NSLocalizedString("pos.cashSession.current.payOut", value: "Pay out", comment: "Record cash removed from drawer")
        static let recordMovement = NSLocalizedString("pos.cashSession.current.recordMovement", value: "Record Pay in/out", comment: "Cash movement menu")
        static let expectedCash = NSLocalizedString("pos.cashSession.current.expected", value: "Expected cash in drawer", comment: "Expected cash amount")
        static let cashSales = NSLocalizedString("pos.cashSession.current.sales", value: "Cash sales", comment: "Cash sales total")
        static let paidInOut = NSLocalizedString("pos.cashSession.current.paidInOut", value: "Paid in/out", comment: "Cash movements total")
        static let cashRefunds = NSLocalizedString("pos.cashSession.current.refunds", value: "Cash refunds", comment: "Cash refunds total")
    }
}
