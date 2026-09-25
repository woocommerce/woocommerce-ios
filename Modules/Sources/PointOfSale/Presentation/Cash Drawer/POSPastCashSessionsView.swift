import SwiftUI

/// Detail pane shown when "Past sessions" is selected in `POSCashDrawerView`.
///
/// UI-only prototype: there is no session store to read from yet, so this always shows the empty
/// state. Listing closed sessions is tracked separately once the Foundation team's local interface
/// is available.
struct POSPastCashSessionsView: View {
    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.title, backButtonConfiguration: nil)

            POSListEmptyView(viewModel: POSPastCashSessionsEmptyViewModel())
        }
        .background(Color.posSurface)
        .accessibilityIdentifier("pos-cash-drawer-past-sessions-view")
    }
}

private struct POSPastCashSessionsEmptyViewModel: POSListEmptyViewModelProtocol {
    var title: String { POSPastCashSessionsView.Localization.emptyTitle }
    var subtitle: String { POSPastCashSessionsView.Localization.emptySubtitle }
    var buttonTitle: String? { nil }
    var icon: Image { Image(systemName: "clock.arrow.circlepath") }
}

private extension POSPastCashSessionsView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSalePastCashSessionsView.title",
            value: "Past sessions",
            comment: "Title of the past cash drawer sessions screen."
        )

        static let emptyTitle = NSLocalizedString(
            "pointOfSalePastCashSessionsView.emptyTitle",
            value: "No past sessions yet",
            comment: "Title shown when there are no past cash drawer sessions to show."
        )

        static let emptySubtitle = NSLocalizedString(
            "pointOfSalePastCashSessionsView.emptySubtitle",
            value: "Closed cash drawer sessions will appear here.",
            comment: "Subtitle shown when there are no past cash drawer sessions to show."
        )
    }
}

#if DEBUG
#Preview {
    POSPastCashSessionsView()
}
#endif
