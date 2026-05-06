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
        var hasText = false

        for segment in message.segments {
            switch segment {
            case .text:
                hasText = true
            case .toolCall(let id, _, _, _, _):
                lastToolCallID = id
            case .cardRender, .toolResult, .confirmation:
                break
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
            case .toolResult:
                return false
            }
        }

        let deduped = MessageBubble.dedupedCardRenders(filtered)
        return hasText ? deferCardsAfterText(deduped) : deduped
    }

    /// Drops later `.cardRender` segments that target the same `(family, entityID)`.
    /// `orders_get` and `show_cards` can both emit a card for the same entity in
    /// one turn; without this, the renderer paints two rows for one id.
    static func dedupedCardRenders(_ segments: [MessageSegment]) -> [MessageSegment] {
        var keysSeen: Set<CardKey> = []
        var dropIDs: Set<UUID> = []
        for segment in segments {
            guard case .cardRender(let id, let toolCallID, _, _) = segment,
                  let key = cardKey(fromSyntheticToolCallID: toolCallID) else { continue }
            if keysSeen.contains(key) {
                dropIDs.insert(id)
            } else {
                keysSeen.insert(key)
            }
        }
        guard dropIDs.isEmpty == false else { return segments }
        return segments.filter { dropIDs.contains($0.id) == false }
    }

    private struct CardKey: Hashable {
        let family: String
        let entityID: String
    }

    /// Synthetic `.cardRender` toolCallID format from `AgenticLoopOrchestrator`:
    /// `"<callID>:card:<index>:<family>:<id>"`. Returns `nil` for any other shape
    /// so unknown IDs survive dedupe untouched.
    private static func cardKey(fromSyntheticToolCallID toolCallID: String) -> CardKey? {
        let parts = toolCallID.split(separator: ":", omittingEmptySubsequences: false)
        guard let markerIndex = parts.indices.first(where: { parts[$0] == "card" }),
              let entityIDStartIndex = parts.index(markerIndex, offsetBy: 3, limitedBy: parts.endIndex),
              entityIDStartIndex < parts.endIndex else {
            return nil
        }
        let familyIndex = parts.index(markerIndex, offsetBy: 2)
        let entityID = parts[entityIDStartIndex...].joined(separator: ":")
        guard !parts[familyIndex].isEmpty, !entityID.isEmpty else { return nil }
        return CardKey(family: String(parts[familyIndex]), entityID: entityID)
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
        case .cardRender:
            return true
        case .text, .toolCall, .toolResult, .confirmation:
            return false
        }
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
        case .toolResult:
            // .toolResult is filtered in orderedSegments; arm kept so future leaks compile-error here.
            EmptyView()
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
