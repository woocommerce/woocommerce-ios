import SwiftUI
import Yosemite

/// A single row in the chat history list — title (or fallback) plus a relative date.
///
struct SupportChatHistoryRow: View {
    let summary: SupportChatSummary

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.title ?? Localization.untitledFallback)
                .font(.body)
                .lineLimit(1)
            Text(Self.dateFormatter.localizedString(for: summary.updatedAt, relativeTo: Date()))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private extension SupportChatHistoryRow {
    enum Localization {
        static let untitledFallback = NSLocalizedString(
            "supportChatHistoryRow.untitledFallback",
            value: "Untitled chat",
            comment: "Fallback title for a support chat history row when no title was captured"
        )
    }
}
