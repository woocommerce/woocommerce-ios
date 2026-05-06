import SwiftUI

struct MessageBubble: View {

    let message: ChatMessage

    @Environment(\.assistantConfirmationHandler) private var confirmationHandler

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .user { Spacer(minLength: AssistantSpacing.xxLarge) }
            VStack(alignment: alignment, spacing: AssistantSpacing.large) {
                ForEach(renderableGroups, id: \.identifier) { group in
                    groupView(for: group)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.snappy(duration: 0.2), value: renderableGroups.map(\.identifier))
            if message.role == .assistant { Spacer(minLength: AssistantSpacing.xxLarge) }
        }
        .frame(maxWidth: .infinity,
               alignment: message.role == .user ? .trailing : .leading)
    }

    var renderableGroups: [MessageSegmentGrouping.Group] {
        MessageSegmentGrouping.group(orderedSegments)
    }

    private var alignment: HorizontalAlignment {
        message.role == .user ? .trailing : .leading
    }

    var orderedSegments: [MessageSegment] {
        guard message.role == .assistant else { return message.segments }

        var lastToolCallID: UUID?
        var hasCardRender = false
        var hasText = false
        var firstSearchNonEmpty: UUID?
        var lastListNonEmpty: UUID?
        var lastStrictAny: UUID?
        var lastSingle: UUID?
        var analyticsIDs: [UUID] = []

        for segment in message.segments {
            switch segment {
            case .text:
                hasText = true
            case .cardRender:
                hasCardRender = true
            case .toolCall(let id, _, _, _, _):
                lastToolCallID = id
            case .toolResult(let id, _, let name, let payload):
                if name.hasPrefix("analytics_") {
                    analyticsIDs.append(id)
                    continue
                }
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
            case .confirmation:
                break
            }
        }

        var renderableToolResultIDs: Set<UUID> = []
        if !hasCardRender, !message.isStreaming {
            renderableToolResultIDs = Set(analyticsIDs)
            if let pick = firstSearchNonEmpty ?? lastListNonEmpty ?? lastStrictAny ?? lastSingle {
                renderableToolResultIDs.insert(pick)
            }
        }

        let filtered = message.segments.filter { segment in
            switch segment {
            case .text, .confirmation:
                return true
            case .cardRender:
                return !message.isStreaming
            case .toolCall(let id, _, _, _, _):
                return id == lastToolCallID
            case .toolResult(let id, _, _, _):
                return renderableToolResultIDs.contains(id)
            }
        }

        return hasText ? deferCardsAfterText(filtered) : filtered
    }

    private func deferCardsAfterText(_ segments: [MessageSegment]) -> [MessageSegment] {
        var deferred: [MessageSegment] = []
        var rest: [MessageSegment] = []
        for segment in segments {
            if isCardSegment(segment) {
                deferred.append(segment)
            } else {
                rest.append(segment)
            }
        }
        guard !deferred.isEmpty else { return segments }
        return rest + deferred
    }

    private func isCardSegment(_ segment: MessageSegment) -> Bool {
        switch segment {
        case .cardRender, .toolResult:
            return true
        case .text, .toolCall, .confirmation:
            return false
        }
    }

    private func arrayCount(_ value: AnyCodableJSON) -> Int {
        if case .array(let elements) = value { return elements.count }
        if case .object(let fields) = value, case .int(let count) = fields["count"] {
            return Int(count)
        }
        return 0
    }

    @ViewBuilder
    private func groupView(for group: MessageSegmentGrouping.Group) -> some View {
        switch group {
        case .solo(let segment):
            segmentView(for: segment)
        case .cardRun(let family, let segments):
            let payloads = segments.compactMap { segment -> AnyCodableJSON? in
                if case .cardRender(_, _, _, let payload) = segment { return payload }
                return nil
            }
            MessageCardListHost(family: family, payloads: payloads)
        }
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
        case .confirmation(_, let proposalID, _, let preview, let status):
            ConfirmationCard(proposalID: proposalID,
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
            .tint(bubbleTextColor)
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
