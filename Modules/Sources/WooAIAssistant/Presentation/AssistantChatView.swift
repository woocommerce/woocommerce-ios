import SwiftUI

public struct AssistantChatView: View {

    @Bindable private var controller: AssistantController
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    private let onClose: () -> Void

    public init(controller: AssistantController,
                onClose: @escaping () -> Void = {}) {
        self.controller = controller
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList

                InputBar(draft: $draft,
                         canSend: controller.canSend,
                         isStreaming: isAssistantResponding,
                         pendingConfirmation: hasPendingConfirmation,
                         onSend: send,
                         onStop: { controller.cancel() })
                    .focused($inputFocused)
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
                    Button(action: newConversation) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.accent))
                    }
                    .accessibilityLabel(Localization.newConversation)
                    .disabled(!controller.canSend)
                }
            }
            .environment(\.assistantConfirmationHandler,
                          AssistantConfirmationHandler(
                            onConfirm: { id in controller.confirmProposal(id) },
                            onCancel: { id in controller.cancelProposal(id) }))
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
                        onPickPrompt: { draft = $0; inputFocused = true })
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
        for message in controller.conversation.messages {
            for segment in message.segments {
                if case .confirmation(_, _, _, _, let status) = segment, status == .pending {
                    return true
                }
            }
        }
        return false
    }

    private func send() {
        let prompt = draft
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        controller.send(prompt)
        draft = ""
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
        return AssistantChatView(controller: configuration.controller, onClose: {})
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
