import SwiftUI

struct ToolActivityPill: View {

    let toolName: String
    let status: ToolCallStatus

    var body: some View {
        HStack(spacing: AssistantSpacing.small) {
            icon
                .accessibilityHidden(true)
            Text(title)
                .font(.assistantCaption)
                .foregroundStyle(Color.assistantBubbleAssistantText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AssistantSpacing.medium)
        .padding(.vertical, AssistantSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AssistantRadius.medium)
                .stroke(Color.assistantSurfaceBorder, lineWidth: 1)
        )
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
