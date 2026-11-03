import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard

/// SwiftUI view for the inbox messages dashboard card.
///
struct StoreInboxDashboardCard: View {
    @ObservedObject private var viewModel: InboxDashboardCardViewModel
    private let onShowAllInboxMessages: () -> Void

    init(viewModel: InboxDashboardCardViewModel, onShowAllInboxMessages: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onShowAllInboxMessages = onShowAllInboxMessages
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if viewModel.syncingError != nil && viewModel.noteRowViewModels.isEmpty {
                    errorState
                } else if viewModel.syncingData {
                    loadingStateView
                } else if viewModel.noteRowViewModels.isNotEmpty {
                    messageList
                    StoreDashboardCardFooterAction(Localization.viewAll, action: showAllInboxMessages)
                } else {
                    emptyStateView
                }
            }
        }
    }
}

private extension StoreInboxDashboardCard {
    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.inbox.name,
                                 showsError: viewModel.syncingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismissInbox)
            }
        }
    }

    var loadingStateView: some View {
        ForEach(InboxViewModel.placeholderRowViewModels) { rowViewModel in
            StoreDashboardInboxNoteRow(viewModel: rowViewModel)
                .redacted(reason: .placeholder)
                .shimmering()
        }
    }

    var messageList: some View {
        VStack(spacing: StoreSpacing.s0) {
            ForEach(viewModel.noteRowViewModels) { rowViewModel in
                StoreDashboardInboxNoteRow(viewModel: rowViewModel)
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: StoreSpacing.s5) {
            Image(uiImage: .emptyInboxNotesImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.emptyStateImageWidth)
                .accessibilityHidden(true)

            Text(Localization.emptyStateTitle)
                .multilineTextAlignment(.center)
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(.storeOnSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(StorePadding.p5)
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .inbox))
            Task { await viewModel.reloadData() }
        }
    }

    func showAllInboxMessages() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .inbox))
        onShowAllInboxMessages()
    }
}

private extension StoreInboxDashboardCard {
    enum Layout {
        static let emptyStateImageWidth: CGFloat = 168
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "inboxDashboardCard.hideCard",
            value: "Hide Inbox",
            comment: "Menu item to dismiss the Inbox section on the Dashboard screen"
        )
        static let viewAll = NSLocalizedString(
            "inboxDashboardCard.viewAll",
            value: "View all messages",
            comment: "Button to navigate to Inbox messages list screen."
        )
        static let emptyStateTitle = NSLocalizedString(
            "inboxDashboardCard.emptyStateTitle",
            value: "No unread messages",
            comment: "Title displayed if there are no inbox notes in the Inbox section on the Dashboard screen."
        )
    }
}

#Preview {
    StoreInboxDashboardCard(viewModel: .init(siteID: 123)) {}
}
