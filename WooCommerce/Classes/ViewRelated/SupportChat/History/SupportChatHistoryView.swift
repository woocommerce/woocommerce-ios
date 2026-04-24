import SwiftUI

/// List of previously-stored support chats. Supports swipe-to-delete.
/// Tap-to-continue is deferred to a later iteration.
///
struct SupportChatHistoryView: View {
    @State private var viewModel: SupportChatHistoryViewModel

    init(viewModel: SupportChatHistoryViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.summaries.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle(Localization.title)
        .task {
            viewModel.load()
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.summaries, id: \.chatID) { summary in
                SupportChatHistoryRow(summary: summary)
            }
            .onDelete { indexSet in
                viewModel.delete(at: indexSet)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(Localization.emptyState)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

private extension SupportChatHistoryView {
    enum Localization {
        static let title = NSLocalizedString(
            "supportChatHistoryView.title",
            value: "Chat History",
            comment: "Navigation title for the support chat history screen"
        )
        static let emptyState = NSLocalizedString(
            "supportChatHistoryView.emptyState",
            value: "You haven't chatted with support yet.",
            comment: "Empty state message shown when there are no stored support chats"
        )
    }
}
