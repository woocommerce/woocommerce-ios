import SwiftUI

struct POSCurrentCashSessionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @State private var entryAction: POSCashSessionEntryView.Action?

    let controller: POSCashSessionController
    let onClosed: (Int64) -> Void

    private var money: POSCashSessionMoney { .init(settings: currencyProvider.currencySettings, session: controller.currentSession) }

    var body: some View {
        if let session = controller.currentSession {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(title: horizontalSizeClass == .compact ? Localization.compactTitle : Localization.title,
                                  subtitle: String.localizedStringWithFormat(Localization.sessionNumber, String(session.id)),
                                  trailingContent: {
                    if horizontalSizeClass != .compact {
                        headerActions
                    }
                }, bottomContent: {
                    if horizontalSizeClass == .compact {
                        headerActions
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, POSPadding.small)
                    }
                })

                ScrollView {
                    VStack(alignment: .leading, spacing: POSSpacing.medium) {
                        if controller.hasPendingCashMovements {
                            POSNoticeView(title: Localization.pendingTitle,
                                          icon: Image(systemName: "exclamationmark.triangle"), style: .alertLowest) {
                                VStack(alignment: .leading, spacing: POSSpacing.small) {
                                    Text(Localization.pendingMessage)
                                    Button(controller.isRetryingCashMovements ? Localization.retrying : Localization.retry) {
                                        Task { await controller.retryPendingCashMovements() }
                                    }
                                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                                    .disabled(controller.isRetryingCashMovements)
                                }
                            }
                        }
                        if let drawerID = session.drawerID, !drawerID.isEmpty {
                            POSCashSessionDrawerView(drawerID: drawerID)
                        }
                        POSInformationCard {
                            POSCashSessionMetricView(label: Localization.expectedCash, amount: money.format(session.expectedCash))
                        }

                        HStack(alignment: .top, spacing: POSSpacing.small) {
                            POSInformationCard {
                                POSCashSessionMetricView(label: Localization.cashSales, amount: money.format(session.cashSales),
                                                         labelMinHeight: compactMetricLabelHeight)
                            }
                            POSInformationCard {
                                POSCashSessionMetricView(label: Localization.paidInOut, amount: money.format(session.paidInOut),
                                                         labelMinHeight: compactMetricLabelHeight)
                            }
                            POSInformationCard {
                                POSCashSessionMetricView(label: Localization.cashRefunds, amount: money.format(-session.cashRefunds),
                                                         labelMinHeight: compactMetricLabelHeight)
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

    private var headerActions: some View {
        HStack(spacing: POSSpacing.small) {
            Button(Localization.closeButton) { entryAction = .close }
                .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .primary, isLoading: false))
                .disabled(controller.hasPendingCashMovements)
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
    }

    private var compactMetricLabelHeight: CGFloat? {
        horizontalSizeClass == .compact ? POSSpacing.xxLarge : nil
    }
}

struct POSCashSessionMetricView: View {
    let label: String
    let amount: String
    var amountColor: Color = .posOnSurface
    var labelMinHeight: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(label)
                .font(.posBodySmallRegular())
                .foregroundStyle(.secondary)
                .frame(minHeight: labelMinHeight, alignment: .topLeading)
            Text(amount)
                .font(.posBodyLargeBold)
                .foregroundStyle(amountColor)
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
        static let compactTitle = NSLocalizedString("pos.cashSession.current.compactTitle", value: "Cash session",
                                                    comment: "Current cash session title on iPhone")
        static let sessionNumber = NSLocalizedString("pos.cashSession.current.number", value: "#%1$@", comment: "Cash session number")
        static let closeButton = NSLocalizedString("pos.cashSession.current.close", value: "Close session", comment: "Close current cash session")
        static let payIn = NSLocalizedString("pos.cashSession.current.payIn", value: "Pay in", comment: "Record cash added to drawer")
        static let payOut = NSLocalizedString("pos.cashSession.current.payOut", value: "Pay out", comment: "Record cash removed from drawer")
        static let recordMovement = NSLocalizedString("pos.cashSession.current.recordMovement", value: "Record Pay in/out", comment: "Cash movement menu")
        static let expectedCash = NSLocalizedString("pos.cashSession.current.expected", value: "Expected cash in drawer", comment: "Expected cash amount")
        static let cashSales = NSLocalizedString("pos.cashSession.current.sales", value: "Cash sales", comment: "Cash sales total")
        static let paidInOut = NSLocalizedString("pos.cashSession.current.paidInOut", value: "Paid in/out", comment: "Cash movements total")
        static let cashRefunds = NSLocalizedString("pos.cashSession.current.refunds", value: "Cash refunds", comment: "Cash refunds total")
        static let pendingTitle = NSLocalizedString("pos.cashSession.current.pendingTitle", value: "Cash activity needs to sync",
                                                    comment: "Title for cash sales or refunds awaiting session recording")
        static let pendingMessage = NSLocalizedString("pos.cashSession.current.pendingMessage",
                                                      value: "Some cash payments or refunds have not updated this session. Retry before closing it.",
                                                      comment: "Explains why a cash session cannot close yet")
        static let retry = NSLocalizedString("pos.cashSession.current.retry", value: "Retry", comment: "Retry pending cash activity")
        static let retrying = NSLocalizedString("pos.cashSession.current.retrying", value: "Retrying…", comment: "Pending cash activity is syncing")
    }
}
