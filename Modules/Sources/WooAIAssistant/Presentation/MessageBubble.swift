import SwiftUI

struct MessageBubble: View {

    let message: ChatMessage
    var showToolActivity: Bool = true

    @Environment(\.assistantConfirmationHandler) private var confirmationHandler

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user { Spacer(minLength: AssistantSpacing.xxLarge) }
            VStack(alignment: alignment, spacing: AssistantSpacing.large) {
                ForEach(orderedSegments) { segment in
                    segmentView(for: segment)
                }
            }
            if message.role == .assistant { Spacer(minLength: AssistantSpacing.xxLarge) }
        }
        .frame(maxWidth: .infinity,
               alignment: message.role == .user ? .trailing : .leading)
    }

    private var alignment: HorizontalAlignment {
        message.role == .user ? .trailing : .leading
    }

    var orderedSegments: [MessageSegment] {
        guard message.role == .assistant else { return message.segments }

        var lastToolCallID: UUID?
        var fallbackToolResultID: UUID?
        let hasCardRender = message.segments.contains { if case .cardRender = $0 { return true }; return false }

        for segment in message.segments {
            if case .toolCall(let id, _, _, _, _) = segment {
                lastToolCallID = id
            }
        }
        if !hasCardRender, !message.isStreaming {
            fallbackToolResultID = pickFallbackToolResultID()
        }

        return message.segments.filter { segment in
            switch segment {
            case .text, .cardRender, .confirmation:
                return true
            case .toolCall(let id, _, _, _, _):
                return showToolActivity && id == lastToolCallID
            case .toolResult(let id, _, _, _):
                return id == fallbackToolResultID
            }
        }
    }

    private func pickFallbackToolResultID() -> UUID? {
        var firstSearchNonEmpty: UUID?
        var lastListNonEmpty: UUID?
        var lastStrictAny: UUID?
        var lastSingle: UUID?
        for segment in message.segments {
            guard case .toolResult(let id, _, let name, let payload) = segment else { continue }
            let isSearch = name.hasSuffix("_search")
            let isList = name.hasSuffix("_list")
            let isStrict = isSearch || isList
            let rowCount = arrayCount(payload)
            if isStrict { lastStrictAny = id }
            if isSearch, rowCount > 0, firstSearchNonEmpty == nil {
                firstSearchNonEmpty = id
            } else if isList, rowCount > 0 {
                lastListNonEmpty = id
            } else if !isStrict {
                lastSingle = id
            }
        }
        return firstSearchNonEmpty ?? lastListNonEmpty ?? lastStrictAny ?? lastSingle
    }

    private func arrayCount(_ value: AnyCodableJSON) -> Int {
        if case .array(let elements) = value { return elements.count }
        return 0
    }

    @ViewBuilder
    private func segmentView(for segment: MessageSegment) -> some View {
        switch segment {
        case .text(_, let content):
            if !content.isEmpty {
                textBubble(content)
            }
        case .toolCall(_, _, let name, _, let status):
            ToolActivityPill(toolName: name, status: status)
        case .toolResult(_, _, let name, let payload):
            MessageCardHost(toolName: name, payload: payload)
        case .cardRender(_, _, let name, let payload):
            MessageCardHost(toolName: name, payload: payload)
        case .confirmation(_, let proposalID, let toolName, let preview, let status):
            ConfirmationCard(proposalID: proposalID,
                             toolName: toolName,
                             preview: preview,
                             status: status,
                             onConfirm: { confirmationHandler.onConfirm(proposalID) },
                             onCancel: { confirmationHandler.onCancel(proposalID) })
        }
    }

    private func textBubble(_ content: String) -> some View {
        Text(renderedText(content))
            .font(.assistantBody)
            .foregroundStyle(bubbleTextColor)
            .padding(.horizontal, AssistantSpacing.medium)
            .padding(.vertical, AssistantSpacing.bubbleVerticalInset)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.bubble))
            .textSelection(.enabled)
    }

    private var bubbleBackground: Color {
        message.role == .user ? Color.assistantBubbleUser : Color.assistantBubbleAssistant
    }

    private var bubbleTextColor: Color {
        message.role == .user ? Color.assistantBubbleUserText : Color.assistantBubbleAssistantText
    }

    private func renderedText(_ content: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        do {
            return try AttributedString(markdown: content, options: options)
        } catch {
            return AttributedString(content)
        }
    }

}

#if DEBUG
#Preview("User") {
    MessageBubble(message: MockAssistantController.userMessage("How many orders today?"))
        .padding()
}

#Preview("Assistant text + card (in chat)") {
    AssistantChatView.preview(.textPlusCard)
}

#Preview("Streaming text (in chat)") {
    AssistantChatView.preview(.assistantStreamingText)
}
#endif
