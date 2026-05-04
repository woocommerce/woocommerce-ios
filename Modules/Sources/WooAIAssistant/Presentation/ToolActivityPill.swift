import SwiftUI

struct ToolActivityPill: View {

    let toolName: String
    let status: ToolCallStatus

    @State private var isExpanded = false

    var body: some View {
        if hasExpandableSummary {
            Button(action: toggle) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.xSmall) {
            HStack(spacing: AssistantSpacing.small) {
                icon
                    .accessibilityHidden(true)
                Text(title)
                    .font(.assistantCaption)
                    .foregroundStyle(Color.assistantBubbleAssistantText)
                Spacer(minLength: 0)
                if hasExpandableSummary {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.assistantMuted)
                        .accessibilityHidden(true)
                }
            }
            if isExpanded, case .completed(let summary?) = status {
                Text(summary)
                    .font(.assistantMonospaced)
                    .foregroundStyle(Color.assistantBubbleAssistantText)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, AssistantSpacing.medium)
        .padding(.vertical, AssistantSpacing.small)
        .frame(minHeight: 44, alignment: .leading)
        .background(Color.assistantToolBackground)
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.medium))
    }

    private func toggle() {
        guard hasExpandableSummary else { return }
        withAnimation(.smooth(duration: AssistantMotion.snap)) {
            isExpanded.toggle()
        }
    }

    private var hasExpandableSummary: Bool {
        if case .completed(let summary) = status, summary != nil { return true }
        return false
    }

    @ViewBuilder
    private var icon: some View {
        switch status {
        case .running:
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.accent))
                .symbolEffect(.pulse.byLayer, options: .repeating)
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.assistantSuccess)
                .contentTransition(.symbolEffect(.replace))
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.assistantError)
        }
    }

    private var title: String {
        let label = String.assistantHumanizedToolToken(toolName)
        switch status {
        case .running: return String(format: Localization.runningFormat, label)
        case .completed: return String(format: Localization.completedFormat, label)
        case .failed(let message): return String(format: Localization.failedFormat, label, message)
        }
    }

    private enum Localization {
        static let runningFormat = NSLocalizedString(
            "assistant.tool.running",
            value: "Using %1$@…",
            comment: "Tool call running: %1$@ is the tool name"
        )
        static let completedFormat = NSLocalizedString(
            "assistant.tool.completed",
            value: "Used %1$@",
            comment: "Tool call completed: %1$@ is the tool name"
        )
        static let failedFormat = NSLocalizedString(
            "assistant.tool.failed",
            value: "%1$@ failed: %2$@",
            comment: "Tool call failed: %1$@ is the tool name, %2$@ is the failure message"
        )
    }
}

#if DEBUG
#Preview("In chat") {
    AssistantChatView.preview(.toolActivityPill)
}

#Preview("Running") {
    ToolActivityPill(toolName: "customers_search", status: .running)
        .padding()
}

#Preview("Completed") {
    ToolActivityPill(toolName: "orders_list",
                     status: .completed(summary: "[ {id: 3479}, {id: 3478} ]"))
        .padding()
}
#endif
