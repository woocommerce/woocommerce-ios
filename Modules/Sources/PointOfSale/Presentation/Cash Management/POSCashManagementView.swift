import SwiftUI

/// Cash management screen with current and past sessions from an injected session controller.
struct POSCashManagementView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: SidebarNavigation?
    @State private var selectedPastSessionID: Int64?
    @State private var isLoaded = false

    let controller: POSCashSessionController

    var body: some View {
        Group {
            if !isLoaded || controller.currentLoadError != nil || controller.isCashSessionsUnsupported {
                sessionStatusView
            } else {
                POSNavigationSplitView(selection: $selection) { selection in
                    POSCashManagementListView(selection: selection, hasCurrentSession: controller.currentSession != nil)
                } detail: { selection, _ in
                    detailView(for: selection)
                        .environment(\.posHeaderBackButtonConfiguration,
                                     horizontalSizeClass == .compact ?
                                        .init(state: .enabled, action: { self.selection = nil }) : nil)
                } detailPlaceholderView: {
                    POSCashManagementEmptyDetailView()
                } setDefaultValue: {
                    if selection == nil {
                        selection = controller.currentSession == nil ? .startSession : .currentSession
                    }
                }
            }
        }
        .task {
            await loadCurrentSession()
        }
    }

    private var sessionStatusView: some View {
        VStack(spacing: POSSpacing.none) {
            POSCashManagementHeaderView()

            if controller.isCashSessionsUnsupported {
                POSListEmptyView(viewModel: POSCashManagementUnsupportedViewModel())
            } else if let error = controller.currentLoadError {
                POSListEmptyView(viewModel: POSCashManagementLoadErrorViewModel(message: error),
                                 onAction: { Task { await loadCurrentSession() } })
            } else {
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.posSurface)
    }

    private func loadCurrentSession() async {
        isLoaded = false
        await controller.loadCurrentSession()
        guard controller.currentLoadError == nil else { return }
        selection = controller.currentSession == nil ? .startSession : .currentSession
        isLoaded = true
    }

    @ViewBuilder
    private func detailView(for selection: SidebarNavigation) -> some View {
        switch selection {
        case .startSession:
            POSStartCashSessionView(controller: controller, onStarted: { self.selection = .currentSession })
        case .currentSession:
            POSCurrentCashSessionView(controller: controller, onClosed: { sessionID in
                selectedPastSessionID = sessionID
                self.selection = .pastSessions
            })
        case .pastSessions:
            POSPastCashSessionsView(selectedSessionID: $selectedPastSessionID, controller: controller)
        }
    }
}

private struct POSCashManagementLoadErrorViewModel: POSListEmptyViewModelProtocol {
    let message: String
    var title: String { POSCashManagementView.Localization.errorTitle }
    var subtitle: String { message }
    var buttonTitle: String? { POSCashManagementView.Localization.retry }
    var icon: Image { Image(systemName: "exclamationmark.triangle") }
}

private struct POSCashManagementUnsupportedViewModel: POSListEmptyViewModelProtocol {
    var title: String { POSCashManagementView.Localization.unsupportedTitle }
    var subtitle: String { POSCashManagementView.Localization.unsupportedMessage }
    var buttonTitle: String? { nil }
    var icon: Image { Image(systemName: "info.circle") }
}

private extension POSCashManagementView {
    struct POSCashManagementHeaderView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.posAnalytics) private var analytics

        var body: some View {
            POSPageHeaderView(
                title: Localization.navigationTitle,
                backButtonConfiguration: .init(state: .enabled,
                                               action: {
                                                   analytics.track(.pointOfSaleCashDrawerCloseButtonTapped)
                                                   dismiss()
                                               }))
            .posHeaderBackButtonIcon(systemName: "xmark")
            .accessibilityAddTraits(.isHeader)
        }
    }

    struct POSCashManagementListView: View {
        @Environment(\.posAnalytics) private var analytics
        @Binding var selection: SidebarNavigation?
        let hasCurrentSession: Bool

        private var primaryNavigation: SidebarNavigation {
            hasCurrentSession ? .currentSession : .startSession
        }

        var body: some View {
            VStack(alignment: .leading, spacing: POSSpacing.none) {
                POSCashManagementHeaderView()

                VStack(spacing: POSSpacing.small) {
                    POSSettingsCard(title: primaryNavigation.title,
                                    subtitle: primaryNavigation.subtitle,
                                    isSelected: selection == primaryNavigation,
                                    action: {
                        if !hasCurrentSession {
                            analytics.track(.pointOfSaleCashDrawerStartSessionTapped)
                        }
                        selection = primaryNavigation
                    })
                    POSSettingsCard(title: SidebarNavigation.pastSessions.title,
                                    subtitle: SidebarNavigation.pastSessions.subtitle,
                                    isSelected: selection == .pastSessions,
                                    action: {
                        analytics.track(.pointOfSaleCashDrawerPastSessionsTapped)
                        selection = .pastSessions
                    })
                    Spacer()
                }
                .padding(.horizontal, POSPadding.medium)
            }
            .background(Color.posSurfaceBright)
            .accessibilityIdentifier("pos-cash-drawer-view")
        }
    }
}

extension POSCashManagementView {
    enum SidebarNavigation: String, CaseIterable, Identifiable {
        case startSession
        case currentSession
        case pastSessions

        var id: Self { self }

        var title: String {
            switch self {
            case .startSession: return Localization.sidebarNavigationStartSessionTitle
            case .currentSession: return Localization.sidebarNavigationCurrentSessionTitle
            case .pastSessions: return Localization.sidebarNavigationPastSessionsTitle
            }
        }

        var subtitle: String {
            switch self {
            case .startSession: return Localization.sidebarNavigationStartSessionSubtitle
            case .currentSession: return Localization.sidebarNavigationCurrentSessionSubtitle
            case .pastSessions: return Localization.sidebarNavigationPastSessionsSubtitle
            }
        }
    }

    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "pointOfSaleCashManagementView.navigationTitle",
            value: "Cash management",
            comment: "Title of the Point of Sale cash management screen."
        )

        static let sidebarNavigationStartSessionTitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationStartSessionTitle",
            value: "Start session",
            comment: "Title of the Start session section within Point of Sale cash management."
        )

        static let sidebarNavigationStartSessionSubtitle = NSLocalizedString(
            "pointOfSaleCashManagementView.sidebarNavigationStartCashSessionSubtitle",
            value: "Start a new cash session",
            comment: "Description of the Start session section within Point of Sale cash management."
        )

        static let sidebarNavigationCurrentSessionTitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationCurrentSessionTitle",
            value: "Current session",
            comment: "Title of the current cash session sidebar section."
        )

        static let sidebarNavigationCurrentSessionSubtitle = NSLocalizedString(
            "pointOfSaleCashManagementView.sidebarNavigationCurrentCashSessionSubtitle",
            value: "Your current cash session",
            comment: "Description of the current cash session sidebar section."
        )

        static let sidebarNavigationPastSessionsTitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationPastSessionsTitle",
            value: "Past sessions",
            comment: "Title of the Past sessions section within Point of Sale cash management."
        )

        static let sidebarNavigationPastSessionsSubtitle = NSLocalizedString(
            "pointOfSaleCashManagementView.sidebarNavigationPastCashSessionsSubtitle",
            value: "See past cash sessions",
            comment: "Description of the Past sessions section within Point of Sale cash management."
        )

        static let errorTitle = NSLocalizedString("pos.cashSession.drawer.errorTitle", value: "Could not load cash sessions", comment: "Cash session error title")
        static let retry = NSLocalizedString("pos.cashSession.drawer.retry", value: "Try again", comment: "Retry loading current cash session")
        static let unsupportedTitle = NSLocalizedString("pos.cashSession.management.unsupportedTitle", value: "Cash management unavailable",
                                                       comment: "Title when the store does not support cash sessions")
        static let unsupportedMessage = NSLocalizedString("pos.cashSession.management.unsupportedMessage",
                                                         value: "Cash sessions are not available on this store.",
                                                         comment: "Message when the store does not support cash sessions")
    }
}

#if DEBUG
#Preview {
    // Production supplies these via `.posFullScreenCover`; the standalone preview provides its own root
    // modal and managers so any future modal has somewhere to render.
    POSCashManagementView(controller: POSCashSessionController(service: POSMockCashSessionService()))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}

#Preview("Current session loading error") {
    POSCashManagementView(controller: POSCashSessionController(service: POSMockCashSessionService(failCurrentLoad: true)))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}

#Preview("Current session loading") {
    POSCashManagementView(controller: POSCashSessionController(service: POSMockCashSessionService(readDelay: .seconds(30))))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}

#Preview("Cash sessions unsupported") {
    POSCashManagementView(controller: POSCashSessionController(service: POSMockCashSessionService(isUnsupported: true)))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}
#endif
