import SwiftUI
import UIKit

struct MessageBubble: View {

    let message: ChatMessage

    @Environment(\.assistantConfirmationHandler) private var confirmationHandler

    @State private var revealedGroupIDs: Set<UUID> = []
    @State private var hasMountedInitialGroups: Bool = false
    @State private var carouselRevealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AssistantSpacing.large) {
            // Confirmation lands above the tool pill: approval has to happen before any tool runs.
            ForEach(confirmationGroups, id: \.identifier) { group in
                renderGroup(group)
            }
            if !toolCallSnapshots.isEmpty {
                ToolActivityCarousel(snapshots: toolCallSnapshots)
                    .opacity(carouselRevealed ? 1 : 0)
                    .animation(.easeOut(duration: 0.12), value: carouselRevealed)
                    .onAppear { handleCarouselAppearance() }
            }
            ForEach(responseGroups, id: \.identifier) { group in
                renderGroup(group)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            // Snap pre-existing groups visible on initial mount so reopening
            // a conversation does not replay reveals or fire haptics.
            revealedGroupIDs = Set(renderableGroups.map(\.identifier))
            carouselRevealed = !toolCallSnapshots.isEmpty
            hasMountedInitialGroups = true
        }
    }

    @ViewBuilder
    private func renderGroup(_ group: MessageSegmentGrouping.Group) -> some View {
        let isRevealed = revealedGroupIDs.contains(group.identifier)
        groupView(for: group)
            .opacity(isRevealed ? 1 : 0)
            // Scope the animation to the opacity flip so concurrent layout changes
            // (streaming text, growing bubble) stay synchronous.
            .animation(.easeOut(duration: 0.1), value: isRevealed)
            .onAppear { handleGroupAppearance(group) }
    }

    private var confirmationGroups: [MessageSegmentGrouping.Group] {
        renderableGroups.filter { Self.isConfirmation($0) }
    }

    private var responseGroups: [MessageSegmentGrouping.Group] {
        renderableGroups.filter { !Self.isConfirmation($0) }
    }

    private static func isConfirmation(_ group: MessageSegmentGrouping.Group) -> Bool {
        if case .solo(.confirmation) = group { return true }
        return false
    }

    private func handleGroupAppearance(_ group: MessageSegmentGrouping.Group) {
        guard hasMountedInitialGroups else { return }
        guard !revealedGroupIDs.contains(group.identifier) else { return }
        if message.role == .assistant {
            AssistantHaptics.gentleTap()
        }
        revealedGroupIDs.insert(group.identifier)
    }

    private func handleCarouselAppearance() {
        guard hasMountedInitialGroups else { return }
        guard !carouselRevealed else { return }
        if message.role == .assistant {
            AssistantHaptics.gentleTap()
        }
        carouselRevealed = true
    }

    var toolCallSnapshots: [ToolCallSnapshot] {
        guard message.role == .assistant else { return [] }
        return message.segments.compactMap { segment in
            if case .toolCall(let id, _, let name, _, let status) = segment {
                return ToolCallSnapshot(id: id, toolName: name, status: status)
            }
            return nil
        }
    }

    var renderableGroups: [MessageSegmentGrouping.Group] {
        MessageSegmentGrouping.group(orderedSegments)
    }

    var orderedSegments: [MessageSegment] {
        guard message.role == .assistant else { return message.segments }

        let hasText = message.segments.contains { segment in
            if case .text = segment { return true }
            return false
        }

        // Tool calls render separately in the carousel; tool results are never shown
        // as a fallback now that show_cards emits synthetic cardRenders.
        let filtered = message.segments.filter { segment in
            switch segment {
            case .text, .confirmation:
                return true
            case .cardRender:
                return !message.isStreaming
            case .toolCall, .toolResult:
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
            soloView(for: segment)
        case .cardRun(let family, let segments):
            let payloads = segments.compactMap { segment -> AnyCodableJSON? in
                if case .cardRender(_, _, _, let payload) = segment { return payload }
                return nil
            }
            MessageCardListHost(family: family, payloads: payloads, sourceMessageID: message.id)
        }
    }

    @ViewBuilder
    private func soloView(for segment: MessageSegment) -> some View {
        switch segment {
        case .text(_, let content):
            if !content.isEmpty {
                if message.role == .user {
                    userTextRow(content)
                } else {
                    assistantText(content)
                }
            }
        case .toolCall(_, _, let name, _, let status):
            ToolActivityPill(toolName: name, status: status)
        case .toolResult:
            // .toolResult is filtered in orderedSegments; arm kept so future leaks compile-error here.
            EmptyView()
        case .cardRender(_, _, let name, let payload):
            MessageCardHost(toolName: name, payload: payload, sourceMessageID: message.id)
        case .confirmation(_, let proposalID, _, let preview, let status):
            ConfirmationCard(proposalID: proposalID,
                             preview: preview,
                             status: status,
                             onConfirm: { confirmationHandler.onConfirm(proposalID) },
                             onCancel: { confirmationHandler.onCancel(proposalID) })
        }
    }

    private func userTextRow(_ content: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: AssistantSpacing.xxLarge)
            userTextBubble(content)
        }
    }

    private func userTextBubble(_ content: String) -> some View {
        Text(renderedText(content))
            .font(.assistantBody)
            .foregroundStyle(Color.assistantBubbleUserText)
            .tint(Color.assistantBubbleUserText)
            .padding(.horizontal, AssistantSpacing.medium)
            .padding(.vertical, AssistantSpacing.bubbleVerticalInset)
            .background(Color.assistantBubbleUser)
            .clipShape(RoundedRectangle(cornerRadius: AssistantRadius.bubble))
            .textSelection(.enabled)
    }

    private func assistantText(_ content: String) -> some View {
        Text(renderedText(content))
            .font(.assistantBody)
            .foregroundStyle(Color.assistantBubbleAssistantText)
            .tint(Color.assistantBubbleAssistantText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
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
