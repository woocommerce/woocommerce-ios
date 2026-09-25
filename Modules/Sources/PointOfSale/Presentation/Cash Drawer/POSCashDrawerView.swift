import SwiftUI

/// Cash drawer screen: a fixed sidebar (Start session / Past sessions) with a detail pane per
/// selection, opened from `POSFloatingControlView`.
///
/// This is a UI-only prototype for the Peacock cash reconciliation meetup. It has no connection to
/// the session or hardware interfaces owned by the other groups yet.
struct POSCashDrawerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: SidebarNavigation?

    var body: some View {
        POSNavigationSplitView(selection: $selection) { selection in
            POSCashDrawerListView(selection: selection)
        } detail: { selection, _ in
            detailView(for: selection)
                .environment(\.posHeaderBackButtonConfiguration,
                             horizontalSizeClass == .compact ?
                                .init(state: .enabled, action: { self.selection = nil }) : nil)
        } detailPlaceholderView: {
            POSCashDrawerEmptyDetailView()
        } setDefaultValue: {
            if selection == nil {
                selection = .startSession
            }
        }
    }

    @ViewBuilder
    private func detailView(for selection: SidebarNavigation) -> some View {
        switch selection {
        case .startSession:
            POSStartCashSessionView()
        case .pastSessions:
            POSPastCashSessionsView()
        }
    }
}

private extension POSCashDrawerView {
    struct POSCashDrawerListView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.posAnalytics) private var analytics
        @Binding var selection: SidebarNavigation?

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
                    POSSettingsCard(title: SidebarNavigation.startSession.title,
                                    subtitle: SidebarNavigation.startSession.subtitle,
                                    isSelected: selection == .startSession,
                                    action: {
                        analytics.track(.pointOfSaleCashDrawerStartSessionTapped)
                        selection = .startSession
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
        case pastSessions

        var id: Self { self }

        var title: String {
            switch self {
            case .startSession: return Localization.sidebarNavigationStartSessionTitle
            case .pastSessions: return Localization.sidebarNavigationPastSessionsTitle
            }
        }

        var subtitle: String {
            switch self {
            case .startSession: return Localization.sidebarNavigationStartSessionSubtitle
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
    }
}

#if DEBUG
#Preview {
    // Production supplies these via `.posFullScreenCover`; the standalone preview provides its own root
    // modal and managers so any future modal has somewhere to render.
    POSCashDrawerView()
        .posRootModal()
        .environmentObject(POSModalManager())
        .environmentObject(POSFullScreenCoverManager())
}
#endif
