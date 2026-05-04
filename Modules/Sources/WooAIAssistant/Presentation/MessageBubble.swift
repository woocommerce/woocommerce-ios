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

        var texts: [MessageSegment] = []
        var lastToolCall: MessageSegment?
        var cardRenders: [MessageSegment] = []
        var toolResults: [MessageSegment] = []
        var confirmations: [MessageSegment] = []

        for segment in message.segments {
            switch segment {
            case .text:
                texts.append(segment)
            case .toolCall:
                lastToolCall = segment
            case .toolResult:
                toolResults.append(segment)
            case .cardRender:
                cardRenders.append(segment)
            case .confirmation:
                confirmations.append(segment)
            }
        }

        var result: [MessageSegment] = []
        if showToolActivity, let pill = lastToolCall {
            result.append(pill)
        }
        result.append(contentsOf: texts)

        if !message.isStreaming {
            if !cardRenders.isEmpty {
                result.append(contentsOf: cardRenders)
            } else if let fallback = fallbackCard(from: toolResults) {
                result.append(fallback)
            }
        }
        result.append(contentsOf: confirmations)
        return result
    }

    private func fallbackCard(from results: [MessageSegment]) -> MessageSegment? {
        var firstSearchNonEmpty: MessageSegment?
        var lastListNonEmpty: MessageSegment?
        var lastStrictAny: MessageSegment?
        var lastSingle: MessageSegment?
        for segment in results {
            guard case .toolResult(_, _, let name, let payload) = segment else { continue }
            let isSearch = name.hasSuffix("_search")
            let isList = name.hasSuffix("_list")
            let isStrict = isSearch || isList
            let rowCount = arrayCount(payload)
            if isStrict { lastStrictAny = segment }
            if isSearch, rowCount > 0, firstSearchNonEmpty == nil {
                firstSearchNonEmpty = segment
            } else if isList, rowCount > 0 {
                lastListNonEmpty = segment
            } else if !isStrict {
                lastSingle = segment
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
