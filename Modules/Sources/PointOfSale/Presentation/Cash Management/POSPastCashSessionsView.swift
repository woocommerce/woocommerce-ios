import SwiftUI

struct POSPastCashSessionsView: View {
    @Binding var detailNavigationPath: NavigationPath
    let controller: POSCashSessionController

    var body: some View {
        sessionList
            .background(Color.posSurface)
            .navigationDestination(for: SessionDestination.self) { destination in
                selectedSessionView(id: destination.id)
                    .toolbar(.hidden, for: .navigationBar)
                    .task(id: destination.id) {
                        await controller.loadSessionDetail(id: destination.id)
                    }
            }
            .task {
                await controller.loadPastSessions()
            }
            .accessibilityIdentifier("pos-cash-drawer-past-sessions-view")
    }

    @ViewBuilder
    private func selectedSessionView(id: Int64) -> some View {
        if let session = controller.sessionDetail, session.id == id {
            POSCashSessionDetailView(session: session, onBack: popDetail)
        } else {
            VStack(spacing: POSSpacing.none) {
                POSPageHeaderView(
                    title: Localization.sessionDetails,
                    backButtonConfiguration: .init(state: .enabled, action: popDetail)
                )
                .environment(\.posHeaderBackButtonConfiguration, .init(state: .enabled, action: popDetail))
                if let message = controller.sessionDetailError {
                    POSListEmptyView(
                        viewModel: POSPastCashSessionsErrorViewModel(title: Localization.detailsError, subtitle: message),
                        onAction: { Task { await controller.loadSessionDetail(id: id) } }
                    )
                } else {
                    loadingView
                }
            }
        }
    }

    private var sessionList: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.title)

            if controller.isLoadingPastSessions {
                loadingView
            } else if let message = controller.pastLoadError {
                POSListEmptyView(
                    viewModel: POSPastCashSessionsErrorViewModel(title: Localization.loadingError, subtitle: message),
                    onAction: { Task { await controller.loadPastSessions(force: true) } }
                )
            } else if controller.pastSessions.isEmpty {
                POSListEmptyView(viewModel: POSPastCashSessionsEmptyViewModel())
            } else {
                ScrollView {
                    LazyVStack(spacing: POSSpacing.small) {
                        ForEach(controller.pastSessions) { session in
                            sessionRow(session)
                                .onAppear {
                                    if controller.pastSessions.last?.id == session.id {
                                        Task { await controller.loadNextPastSessions() }
                                    }
                                }
                        }

                        if controller.isLoadingNextPastSessions {
                            ProgressView()
                                .progressViewStyle(POSProgressViewStyle())
                                .padding(POSPadding.medium)
                                .accessibilityLabel(Localization.loadingMore)
                        } else if let message = controller.pastPageError {
                            POSNoticeView(title: Localization.loadingMoreError,
                                          icon: Image(systemName: "exclamationmark.triangle"),
                                          style: .alertLowest) {
                                VStack(alignment: .leading, spacing: POSSpacing.small) {
                                    Text(message)
                                    Button(Localization.retry) {
                                        Task { await controller.loadNextPastSessions() }
                                    }
                                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                                }
                            }
                        }
                    }
                    .padding(POSPadding.medium)
                }
                .refreshable {
                    await controller.refreshPastSessions()
                }
            }
        }
    }

    private func sessionRow(_ session: POSCashSession) -> some View {
        Button {
            detailNavigationPath.append(SessionDestination(id: session.id))
        } label: {
            HStack(spacing: POSSpacing.medium) {
                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(session.openedAt.formatted(date: .numeric, time: .omitted))
                        .font(.posBodyLargeBold)
                        .foregroundStyle(Color.posOnSurface)
                    Text(String.localizedStringWithFormat(Localization.sessionNumber, String(session.id)))
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(POSPadding.medium)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pos-cash-drawer-past-session-\(session.id)")
    }

    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(POSProgressViewStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(Localization.loading)
    }

    private func popDetail() {
        guard !detailNavigationPath.isEmpty else { return }
        detailNavigationPath.removeLast()
    }

    struct SessionDestination: Hashable {
        let id: Int64
    }
}

private struct POSPastCashSessionsEmptyViewModel: POSListEmptyViewModelProtocol {
    var title: String { POSPastCashSessionsView.Localization.emptyTitle }
    var subtitle: String { POSPastCashSessionsView.Localization.emptySubtitle }
    var buttonTitle: String? { nil }
    var icon: Image { Image(systemName: "clock.arrow.circlepath") }
}

private struct POSPastCashSessionsErrorViewModel: POSListEmptyViewModelProtocol {
    let title: String
    let subtitle: String
    var buttonTitle: String? { POSPastCashSessionsView.Localization.retry }
    var icon: Image { Image(systemName: "exclamationmark.triangle") }
}

private extension POSPastCashSessionsView {
    enum Localization {
        static let title = NSLocalizedString("pointOfSalePastCashSessionsView.title", value: "Past sessions", comment: "Past cash sessions title")
        static let sessionDetails = NSLocalizedString("pos.cashSession.past.details", value: "Session details", comment: "Closed session detail title")
        static let sessionNumber = NSLocalizedString("pos.cashSession.past.number", value: "#%1$@", comment: "Cash session number")
        static let emptyTitle = NSLocalizedString("pointOfSalePastCashSessionsView.emptyTitle", value: "No past sessions yet", comment: "Empty sessions title")
        static let emptySubtitle = NSLocalizedString("pointOfSalePastCashSessionsView.emptyCashSessionsSubtitle",
                                                     value: "Closed cash sessions will appear here.", comment: "Empty sessions subtitle")
        static let loadingError = NSLocalizedString("pos.cashSession.past.loadingError", value: "Could not load past sessions",
                                                    comment: "Past sessions loading error")
        static let detailsError = NSLocalizedString("pos.cashSession.past.detailsError", value: "Could not load session details",
                                                    comment: "Closed session detail loading error")
        static let loadingMoreError = NSLocalizedString("pos.cashSession.past.loadingMoreError", value: "Could not load more sessions",
                                                        comment: "Past sessions next page error")
        static let loading = NSLocalizedString("pos.cashSession.past.loading", value: "Loading sessions",
                                               comment: "Past sessions loading accessibility label")
        static let loadingMore = NSLocalizedString("pos.cashSession.past.loadingMore", value: "Loading more sessions",
                                                   comment: "Past sessions next page accessibility label")
        static let retry = NSLocalizedString("pos.cashSession.past.retry", value: "Try again", comment: "Retry loading cash sessions")
    }
}

#if DEBUG
private struct POSPastCashSessionsPreview: View {
    @State private var navigationPath: NavigationPath
    private let controller: POSCashSessionController

    init(service: POSMockCashSessionService, selectedSessionID: Int64? = nil) {
        var path = NavigationPath()
        if let selectedSessionID {
            path.append(POSPastCashSessionsView.SessionDestination(id: selectedSessionID))
        }
        _navigationPath = State(initialValue: path)
        controller = POSCashSessionController(service: service)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            POSPastCashSessionsView(detailNavigationPath: $navigationPath,
                                    controller: controller)
                .navigationBarHidden(true)
        }
    }
}

#Preview("Past sessions") {
    POSPastCashSessionsPreview(service: POSMockCashSessionService())
}

#Preview("Past session details") {
    POSPastCashSessionsPreview(service: POSMockCashSessionService(), selectedSessionID: 1681891)
}

#Preview("Past session details error") {
    POSPastCashSessionsPreview(service: POSMockCashSessionService(failDetailLoad: true), selectedSessionID: 1681891)
}

#Preview("Past sessions empty") {
    POSPastCashSessionsPreview(service: POSMockCashSessionService(hasSampleHistory: false))
}

#Preview("Past sessions error") {
    POSPastCashSessionsPreview(service: POSMockCashSessionService(failPastLoad: true))
}

#Preview("Past sessions loading") {
    POSPastCashSessionsPreview(service: POSMockCashSessionService(readDelay: .seconds(30)))
}
#endif
