import SwiftUI

public struct AssistantChatView: View {

    @Bindable private var controller: AssistantController
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    private let onClose: () -> Void
    private let onFeedbackTap: (() -> Void)?
    private let siteID: Int64

    public init(controller: AssistantController,
                siteID: Int64,
                onClose: @escaping () -> Void = {},
                onFeedbackTap: (() -> Void)? = nil) {
        self.controller = controller
        self.siteID = siteID
        self.onClose = onClose
        self.onFeedbackTap = onFeedbackTap
    }

    public var body: some View {
        NavigationStack {
            // Pin via safeAreaInset so the scroll content reserves matching
            // bottom space instead of being obscured by the input bar.
            messageList
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    InputBar(draft: $draft,
                             canSend: controller.canSend,
                             isStreaming: isAssistantResponding,
                             pendingConfirmation: hasPendingConfirmation,
                             onSend: send,
                             onStop: { controller.cancel() })
                        .focused($inputFocused)
                        .background(Color.assistantSurface)
                }
                .background(Color.assistantSurface)
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.assistantTextFaint)
                    }
                    .accessibilityLabel(Localization.close)
                }
                ToolbarItem(placement: .principal) {
                    titleToolbarItem
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !controller.conversation.messages.isEmpty {
                        Button(action: newConversation) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(.accent))
                        }
                        .accessibilityLabel(Localization.newConversation)
                    }
                }
            }
            .environment(\.assistantConfirmationHandler,
                          AssistantConfirmationHandler(
                            onConfirm: { id in controller.confirmProposal(id) },
                            onCancel: { id in controller.cancelProposal(id) }))
            .environment(\.assistantCardTelemetry,
                          AssistantCardTelemetryDispatcher(
                            tracker: controller.telemetryTracker,
                            contextLookup: { [conversation = controller.conversation] messageID in
                                conversation.telemetryContext(for: messageID)
                            }))
            .onDisappear {
                if !controller.canSend {
                    controller.cancel()
                }
            }
        }
    }

    private var titleToolbarItem: some View {
        HStack(spacing: AssistantSpacing.xSmall) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.accent))
            Text(Localization.title)
                .font(.assistantBodyEmphasized)
        }
    }

    private var messageList: some View {
        MessageListView(messages: controller.conversation.messages,
                        streamingState: controller.conversation.streamingState,
                        siteID: siteID,
                        onPickPrompt: { draft = $0; inputFocused = true },
                        onSendSuggestion: sendSuggestion,
                        onFeedbackTap: onFeedbackTap)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { inputFocused = false }
            )
    }

    private var isAssistantResponding: Bool {
        guard !hasPendingConfirmation else { return false }
        switch controller.conversation.streamingState {
        case .sending, .streaming:
            return true
        case .idle, .failed, .outcomeUnknown:
            return false
        }
    }

    private var hasPendingConfirmation: Bool {
        controller.conversation.messages.hasPendingConfirmation
    }

    private func send() {
        let prompt = draft
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        controller.send(prompt)
        draft = ""
        inputFocused = false
    }

    private func sendSuggestion(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        controller.send(trimmed)
        draft = ""
        inputFocused = false
    }

    private func newConversation() {
        draft = ""
        controller.startNewConversation()
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantChat.nav.title",
            value: "Assistant",
            comment: "Title of the AI Assistant chat screen"
        )
        static let close = NSLocalizedString(
            "assistantChat.nav.close",
            value: "Close",
            comment: "Accessibility label for the close button in the AI Assistant chat navigation bar"
        )
        static let newConversation = NSLocalizedString(
            "assistantChat.nav.newConversation",
            value: "New conversation",
            comment: "Accessibility label for the new-conversation button in the AI Assistant chat navigation bar"
        )
    }
}

#if DEBUG
extension AssistantChatView {

    @MainActor
    static func preview(_ scenario: AssistantChatScenario) -> some View {
        let configuration = AssistantChatScenarioBuilder(scenario: scenario).build()
        return AssistantChatView(controller: configuration.controller, siteID: 0, onClose: {})
    }
}

#Preview("Empty") { AssistantChatView.preview(.empty) }
#Preview("Single user message") { AssistantChatView.preview(.singleUserMessage) }
#Preview("Assistant typing") { AssistantChatView.preview(.assistantTyping) }
#Preview("Assistant streaming text") { AssistantChatView.preview(.assistantStreamingText) }
#Preview("Text + card") { AssistantChatView.preview(.textPlusCard) }
#Preview("Tool activity pill") { AssistantChatView.preview(.toolActivityPill) }
#Preview("Pending confirmation") { AssistantChatView.preview(.pendingConfirmation) }
#Preview("Pending confirmation (bulk)") { AssistantChatView.preview(.pendingConfirmationBulk) }
#Preview("Failed mid-stream") { AssistantChatView.preview(.failedMidStream) }
#Preview("Outcome unknown") { AssistantChatView.preview(.outcomeUnknown) }
#Preview("Multi-turn") { AssistantChatView.preview(.multiTurn) }
#endif
