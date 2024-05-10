import SwiftUI

/// SwiftUI view for the inbox messages dashboard card.
///
struct InboxDashboardCard: View {
    private let viewModel: InboxDashboardCardViewModel

    init(viewModel: InboxDashboardCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)
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
            Text(Localization.title)
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
}

private extension InboxDashboardCard {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "inboxDashboardCard.title",
            value: "Inbox",
            comment: "Title of the Inbox section on the Dashboard screen"
        )
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
    }
}

#Preview {
    InboxDashboardCard(viewModel: .init(siteID: 123))
}
