import SwiftUI

/// Cash drawer screen with current and past sessions from an injected session controller.
struct POSCashDrawerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: SidebarNavigation?
    @State private var selectedPastSessionID: Int64?
    @State private var isLoaded = false

    let controller: POSCashSessionController

    var body: some View {
        Group {
            if let error = controller.currentLoadError {
                POSListEmptyView(viewModel: POSCashDrawerLoadErrorViewModel(message: error),
                                 onAction: { Task { await loadCurrentSession() } })
                    .background(Color.posSurface)
            } else if isLoaded {
                POSNavigationSplitView(selection: $selection) { selection in
                    POSCashDrawerListView(selection: selection, hasCurrentSession: controller.currentSession != nil)
                } detail: { selection, _ in
                    detailView(for: selection)
                        .environment(\.posHeaderBackButtonConfiguration,
                                     horizontalSizeClass == .compact ?
                                        .init(state: .enabled, action: { self.selection = nil }) : nil)
                } detailPlaceholderView: {
                    POSCashDrawerEmptyDetailView()
                } setDefaultValue: {
                    if selection == nil {
                        selection = controller.currentSession == nil ? .startSession : .currentSession
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loadCurrentSession()
        }
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

private struct POSCashDrawerLoadErrorViewModel: POSListEmptyViewModelProtocol {
    let message: String
    var title: String { POSCashDrawerView.Localization.errorTitle }
    var subtitle: String { message }
    var buttonTitle: String? { POSCashDrawerView.Localization.retry }
    var icon: Image { Image(systemName: "exclamationmark.triangle") }
}

private extension POSCashDrawerView {
    struct POSCashDrawerListView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.posAnalytics) private var analytics
        @Binding var selection: SidebarNavigation?
        let hasCurrentSession: Bool

        private var primaryNavigation: SidebarNavigation {
            hasCurrentSession ? .currentSession : .startSession
        }

        var body: some View {
            VStack(alignment: .leading, spacing: POSSpacing.none) {
                POSPageHeaderView(
                    title: Localization.navigationTitle,
                    backButtonConfiguration: .init(state: .enabled,
                                                   action: {
                                                       analytics.track(.pointOfSaleCashDrawerCloseButtonTapped)
                                                       dismiss()
                                                   }))
                .posHeaderBackButtonIcon(systemName: "xmark")
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

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

extension POSCashDrawerView {
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
            "pointOfSaleCashDrawerView.navigationTitle",
            value: "Cash drawer",
            comment: "Title of the Point of Sale cash drawer screen."
        )

        static let sidebarNavigationStartSessionTitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationStartSessionTitle",
            value: "Start session",
            comment: "Title of the Start session section within the Point of Sale cash drawer screen."
        )

        static let sidebarNavigationStartSessionSubtitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationStartSessionSubtitle",
            value: "Start a new cash drawer session",
            comment: "Description of the Start session section within the Point of Sale cash drawer screen."
        )

        static let sidebarNavigationCurrentSessionTitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationCurrentSessionTitle",
            value: "Current session",
            comment: "Title of the current cash drawer session sidebar section."
        )

        static let sidebarNavigationCurrentSessionSubtitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationCurrentSessionSubtitle",
            value: "Your current cash drawer session",
            comment: "Description of the current cash drawer session sidebar section."
        )

        static let sidebarNavigationPastSessionsTitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationPastSessionsTitle",
            value: "Past sessions",
            comment: "Title of the Past sessions section within the Point of Sale cash drawer screen."
        )

        static let sidebarNavigationPastSessionsSubtitle = NSLocalizedString(
            "pointOfSaleCashDrawerView.sidebarNavigationPastSessionsSubtitle",
            value: "See past cash drawer sessions",
            comment: "Description of the Past sessions section within the Point of Sale cash drawer screen."
        )

        static let errorTitle = NSLocalizedString("pos.cashSession.drawer.errorTitle", value: "Could not load cash sessions", comment: "Cash session error title")
        static let retry = NSLocalizedString("pos.cashSession.drawer.retry", value: "Try again", comment: "Retry loading current cash session")
    }
}

#if DEBUG
#Preview {
    // Production supplies these via `.posFullScreenCover`; the standalone preview provides its own root
    // modal and managers so any future modal has somewhere to render.
    POSCashDrawerView(controller: POSCashSessionController(service: POSMockCashSessionService()))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}

#Preview("Current session loading error") {
    POSCashDrawerView(controller: POSCashSessionController(service: POSMockCashSessionService(failCurrentLoad: true)))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}

#Preview("Current session loading") {
    POSCashDrawerView(controller: POSCashSessionController(service: POSMockCashSessionService(readDelay: .seconds(30))))
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}
#endif
