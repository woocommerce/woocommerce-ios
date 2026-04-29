import SwiftUI
import Yosemite

/// List of previously-stored support chats. Supports swipe-to-delete and tap-to-resume.
///
struct SupportChatHistoryView: View {
    @State private var viewModel: SupportChatHistoryViewModel

    /// Called when the merchant taps a chat to resume it. The host is responsible
    /// for presenting the chat UI seeded with the given `chatID`.
    private let onSelect: (SupportChatSummary) -> Void

    init(viewModel: SupportChatHistoryViewModel,
         onSelect: @escaping (SupportChatSummary) -> Void) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onSelect = onSelect
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
                Button {
                    onSelect(summary)
                } label: {
                    SupportChatHistoryRow(summary: summary)
                }
                .buttonStyle(.plain)
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
