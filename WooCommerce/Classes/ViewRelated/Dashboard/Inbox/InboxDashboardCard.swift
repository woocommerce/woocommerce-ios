import SwiftUI
import struct Yosemite.DashboardCard

/// SwiftUI view for the inbox messages dashboard card.
///
struct InboxDashboardCard: View {
    @ObservedObject private var viewModel: InboxDashboardCardViewModel
    private let onShowAllInboxMessages: () -> Void

    init(viewModel: InboxDashboardCardViewModel, onShowAllInboxMessages: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onShowAllInboxMessages = onShowAllInboxMessages
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, Layout.padding)

            if viewModel.syncingError != nil && viewModel.noteRowViewModels.isEmpty {
                DashboardCardErrorView {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .inbox))
                    Task {
                        await viewModel.reloadData()
                    }
                }
            } else if viewModel.syncingData {
                loadingStateView
            } else if viewModel.noteRowViewModels.isNotEmpty {
                messageList
            } else {
                emptyStateView
            }
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension InboxDashboardCard {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.inbox.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismissInbox()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.syncingData)
        }
    }

    var loadingStateView: some View {
        ForEach(InboxViewModel.placeholderRowViewModels) { rowViewModel in
            InboxNoteRow(viewModel: rowViewModel,
                         dividerPadding: Layout.dividerPadding)
                .redacted(reason: .placeholder)
                .shimmering()
        }
    }

    var messageList: some View {
        VStack(spacing: Layout.padding) {
            VStack(spacing: 0) {
                ForEach(viewModel.noteRowViewModels) { rowViewModel in
                    InboxNoteRow(viewModel: rowViewModel,
                                 shouldHighlightUnreadNoteTitle: false,
                                 contentFont: .subheadline,
                                 dateFont: .footnote,
                                 verticalSpacing: Layout.noteContentVerticalSpacing,
                                 dividerPadding: Layout.dividerPadding)
                }
            }
            viewAllButton
                .padding(.horizontal, Layout.padding)
        }
    }

    var emptyStateView: some View {
        VStack(spacing: Layout.padding) {
            Image(uiImage: .emptyInboxNotesImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.emptyStateImageWidth)
                .accessibility(hidden: true)

            Text(Localization.emptyStateTitle)
                .multilineTextAlignment(.center)
                .headlineStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Layout.padding)
    }

    var viewAllButton: some View {
        Button {
            ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .inbox))
            onShowAllInboxMessages()
        } label: {
            HStack {
                Text(Localization.viewAll)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }
}

private extension InboxDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let emptyStateImageWidth: CGFloat = 168
        static let noteContentVerticalSpacing: CGFloat = 5
        static let dividerPadding = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
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
    InboxDashboardCard(viewModel: .init(siteID: 123)) {}
}
