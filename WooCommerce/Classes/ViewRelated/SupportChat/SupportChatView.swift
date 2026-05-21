import SwiftUI

/// The main chat interface view for AI support.
///
struct SupportChatView: View {
    @Bindable var viewModel: SupportChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var isResolutionConfirmationPresented = false

    var body: some View {
        chatView
            .background(Color(.listBackground))
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.canEscalateToHumanSupport {
                        Button {
                            viewModel.contactHumanSupport(source: .toolbar)
                        } label: {
                            Image(systemName: "person.fill.questionmark")
                                .accessibilityLabel(Localization.toolbarContactSupport)
                        }
                        .onAppear {
                            viewModel.trackManualEscalationButtonShownIfNeeded()
                        }
                    }

                    if viewModel.shouldShowResolvedButton {
                        Button {
                            isResolutionConfirmationPresented = true
                        } label: {
                            Image(systemName: "checkmark")
                                .accessibilityLabel(Localization.toolbarMarkResolved)
                        }
                        .onAppear {
                            viewModel.trackResolutionButtonShownIfNeeded()
                        }
                    }
                }
            }
            .alert(
                Localization.markResolvedConfirmationTitle,
                isPresented: $isResolutionConfirmationPresented,
                actions: {
                    Button(Localization.markResolvedConfirmationConfirm) {
                        viewModel.markChatResolved()
                    }
                    Button(Localization.dismiss, role: .cancel) {}
                },
                message: {
                    Text(Localization.markResolvedConfirmationMessage)
                }
            )
            .alert(
                Localization.errorTitle,
                isPresented: .init(
                    get: { viewModel.state != .idle && viewModel.state != .sending },
                    set: { if !$0 { viewModel.dismissError() } }
                ),
                actions: {
                    Button(Localization.contactSupport) {
                        viewModel.dismissError()
                        viewModel.contactHumanSupport(source: .errorDialog)
                    }
                    Button(Localization.dismiss, role: .cancel) {
                        viewModel.dismissError()
                    }
                },
                message: {
                    if case .error(let message) = viewModel.state {
                        Text(message)
                    }
                }
            )
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            messageList

            if viewModel.hasCreatedTicket {
                ticketCreatedBanner
            } else if viewModel.isChatResolved {
                chatResolvedBanner
            } else if viewModel.shouldPromptHumanSupport {
                humanSupportBanner
            } else if viewModel.shouldShowInputArea {
                Divider()

                inputArea
            }
        }
        .onAppear {
            viewModel.showGreeting()
            viewModel.resumeIfNeeded()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: SupportChatLayout.messageSpacing) {
                    if viewModel.isResumedChat {
                        resumedChatHeader
                    }
                    ForEach(viewModel.messages) { message in
                        messageRow(for: message)
                            .id(message.id)
                    }

                    if viewModel.state == .sending {
                        TypingIndicatorRow()
                            .id("typing")
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.state) { _, newState in
                if newState == .sending {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onChange(of: viewModel.shouldPromptHumanSupport) {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func messageRow(for message: SupportChatViewModel.ChatMessage) -> some View {
        switch message.content {
        case .text(let text):
            VStack(alignment: .leading, spacing: 4) {
                SupportChatMessageRow(role: message.role, text: text, failed: message.failed)

                if message.shouldShowFeedbackButtons, let messageID = message.messageID {
                    SupportChatFeedbackRow(
                        messageID: messageID,
                        rating: viewModel.messageRatings[messageID],
                        onRate: { upvoted in
                            viewModel.submitFeedback(messageID: messageID, upvoted: upvoted)
                        }
                    )
                }
            }

        case .resolvedPrompt:
            SupportChatMessageRow(role: message.role, text: message.content.text ?? "", failed: false)

        case .issuePicker(let issues):
            issuePickerBubble(issues: issues)

        case .diagnosticsProgress(let steps):
            diagnosticsProgressBubble(steps: steps)

        case .diagnosticsSuccess:
            diagnosticsSuccessBubble()

        case .diagnosticsFailure(let result):
            diagnosticsFailureBubble(result: result)
        }
    }

    // MARK: - Issue Picker Bubble

    private func issuePickerBubble(issues: [SupportIssueType]) -> some View {
        VStack(alignment: .leading, spacing: Layout.bubbleSpacing) {
            Text(Localization.issuePickerHeader)
                .font(.body)
                .foregroundStyle(Color(.text))

            ForEach(issues, id: \.self) { issue in
                Button(issue.displayName) {
                    Task {
                        await viewModel.selectIssue(issue)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.selectedIssue != nil)
            }
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Colors.botBubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: SupportChatLayout.bubbleCornerRadius))
        .frame(maxWidth: SupportChatLayout.maxBubbleWidth)
    }

    // MARK: - Diagnostics Progress Bubble

    private func diagnosticsProgressBubble(
        steps: [(test: SupportDiagnosticsService.Test, status: SupportChatViewModel.TestStatus)]
    ) -> some View {
        HStack(alignment: .center, spacing: Layout.resultIconSpacing) {
            let currentStep = steps.first { $0.status == .running } ?? steps.first { $0.status == .pending }
            if let step = currentStep {
                ProgressView()
                    .controlSize(.small)

                Text(step.test.title)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Colors.botBubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: SupportChatLayout.bubbleCornerRadius))
        .frame(maxWidth: SupportChatLayout.maxBubbleWidth)
    }

    // MARK: - Diagnostics Success Bubble

    private func diagnosticsSuccessBubble() -> some View {
        VStack(alignment: .leading, spacing: Layout.resultsSpacing) {
            HStack(alignment: .top, spacing: Layout.resultIconSpacing) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)

                Text(Localization.allChecksPassed)
                    .font(.body)
            }

            Button(Localization.continueToChat) {
                viewModel.proceedToChat()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Colors.botBubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: SupportChatLayout.bubbleCornerRadius))
        .frame(maxWidth: SupportChatLayout.maxBubbleWidth)
    }

    // MARK: - Diagnostics Failure Bubble

    private func diagnosticsFailureBubble(result: SupportDiagnosticsService.Result) -> some View {
        VStack(alignment: .leading, spacing: Layout.resultsSpacing) {
            HStack(alignment: .top, spacing: Layout.resultIconSpacing) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.red)

                Text(result.test.title)
                    .font(.body.weight(.semibold))
            }

            if let errorMessage = result.errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            if let action = result.suggestedAction {
                Button {
                    Task {
                        await viewModel.executeAction(action)
                    }
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isExecutingAction))

                if action == .openPushNotificationPreferences {
                    Button(Localization.continueToChat) {
                        viewModel.proceedToChat()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            } else {
                Button(Localization.continueToChat) {
                    viewModel.proceedToChat()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Colors.botBubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: SupportChatLayout.bubbleCornerRadius))
        .frame(maxWidth: SupportChatLayout.maxBubbleWidth)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.state == .sending {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Resumed Chat Header

    private var resumedChatHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.arrow.circlepath")
            Text(Localization.resumedChatHeader)
        }
        .font(.caption)
        .foregroundColor(Color(.secondaryLabel))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Human Support Banner

    private var humanSupportBanner: some View {
        VStack(spacing: SupportChatLayout.bannerSpacing) {
            Text(Localization.humanSupportMessage)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)

            Button(Localization.contactSupport) {
                viewModel.contactHumanSupport(source: .banner)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        .background(Color(.listBackground))
        .onAppear {
            viewModel.trackBotEscalationButtonShownIfNeeded()
        }
    }

    // MARK: - Ticket Created Banner

    private var ticketCreatedBanner: some View {
        VStack(spacing: SupportChatLayout.bannerSpacing) {
            Text(Localization.ticketCreatedMessage)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.listBackground))
    }

    // MARK: - Chat Resolved Banner

    private var chatResolvedBanner: some View {
        VStack(spacing: SupportChatLayout.bannerSpacing) {
            Text(Localization.chatResolvedMessage)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.listBackground))
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: SupportChatLayout.inputSpacing) {
            TextField(Localization.placeholder, text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessageIfPossible()
                }

            Button {
                sendMessageIfPossible()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: SupportChatLayout.sendButtonSize))
            }
            .disabled(!canSendMessage)
            .opacity(canSendMessage ? 1.0 : SupportChatLayout.disabledOpacity)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSendMessage: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.state != .sending
    }

    private func sendMessageIfPossible() {
        guard canSendMessage else { return }
        isInputFocused = false
        viewModel.sendMessage()
    }
}

// MARK: - Layout Constants

private extension SupportChatView {
    enum Layout {
        static let bubbleSpacing: CGFloat = 8
        static let progressSpacing: CGFloat = 8
        static let resultsSpacing: CGFloat = 12
        static let resultIconSpacing: CGFloat = 6
    }

    enum Colors {
        static let botBubbleBackground = Color(.listForeground(modal: false))
    }
}

// MARK: - Localization

private extension SupportChatView {
    enum Localization {
        static let title = NSLocalizedString(
            "supportChatView.title",
            value: "Chat with Support",
            comment: "Navigation title for the AI support chat screen"
        )
        static let placeholder = NSLocalizedString(
            "supportChatView.placeholder",
            value: "Type a message...",
            comment: "Placeholder text for the chat input field"
        )
        static let errorTitle = NSLocalizedString(
            "supportChatView.errorTitle",
            value: "Error",
            comment: "Title for the error alert in support chat"
        )
        static let dismiss = NSLocalizedString(
            "supportChatView.errorDismiss",
            value: "Dismiss",
            comment: "Cancel button in the support chat error alert"
        )
        static let humanSupportMessage = NSLocalizedString(
            "supportChatView.humanSupportMessage",
            value: "It looks like you might need additional help. Would you like to contact our support team?",
            comment: "Message shown when the bot suggests contacting human support"
        )
        static let ticketCreatedMessage = NSLocalizedString(
            "supportChatView.ticketCreatedMessage",
            value: "A support ticket has been created for this chat. We'll respond via email.",
            comment: "Message shown when a support ticket has already been created for this chat"
        )
        static let chatResolvedMessage = NSLocalizedString(
            "supportChatView.chatResolvedMessage",
            value: "This chat has been marked as resolved.",
            comment: "Message shown when the merchant has marked a support chat as resolved"
        )
        static let contactSupport = NSLocalizedString(
            "supportChatView.contactSupport",
            value: "Contact Support",
            comment: "Button to contact human support from the chat"
        )
        static let toolbarContactSupport = NSLocalizedString(
            "supportChatView.toolbar.contactSupport",
            value: "Contact Support",
            comment: "Trailing toolbar button on the AI support chat that lets the merchant escalate to human support"
        )
        static let toolbarMarkResolved = NSLocalizedString(
            "supportChatView.toolbar.markResolved",
            value: "Mark Resolved",
            comment: "Trailing toolbar button on the AI support chat that lets the merchant mark the chat as resolved"
        )
        static let markResolvedConfirmationTitle = NSLocalizedString(
            "supportChatView.markResolvedConfirmation.title",
            value: "Mark chat as resolved?",
            comment: "Title for the confirmation alert before marking a support chat as resolved"
        )
        static let markResolvedConfirmationMessage = NSLocalizedString(
            "supportChatView.markResolvedConfirmation.message",
            value: "This will close the chat actions for this conversation.",
            comment: "Message for the confirmation alert before marking a support chat as resolved"
        )
        static let markResolvedConfirmationConfirm = NSLocalizedString(
            "supportChatView.markResolvedConfirmation.confirm",
            value: "Mark Resolved",
            comment: "Confirmation button for marking a support chat as resolved"
        )
        static let issuePickerHeader = NSLocalizedString(
            "supportChatView.issuePickerHeader",
            value: "Hello! I'm your Woo Mobile Support Bot. What are you having trouble with today?",
            comment: "Greeting and header for the issue picker in support chat"
        )
        static let runningDiagnostics = NSLocalizedString(
            "supportChatView.runningDiagnostics",
            value: "Running diagnostics...",
            comment: "Message shown while running diagnostics in support chat"
        )
        static let continueToChat = NSLocalizedString(
            "supportChatView.continueToChat",
            value: "Continue to Chat",
            comment: "Button to proceed from diagnostics results to chat"
        )
        static let diagnosticsComplete = NSLocalizedString(
            "supportChatView.diagnosticsComplete",
            value: "Diagnostics Complete",
            comment: "Header shown when diagnostics have finished running"
        )
        static let allChecksPassed = NSLocalizedString(
            "supportChatView.allChecksPassed",
            value: "All checks completed with no issues.",
            comment: "Message shown when all diagnostic checks pass"
        )
        static let resumedChatHeader = NSLocalizedString(
            "supportChatView.resumedChatHeader",
            value: "Continuing previous conversation",
            comment: "Inline separator shown at the top of a chat that was opened from history, signalling that prior messages follow"
        )
    }
}

#Preview("Issue Picker") {
    NavigationStack {
        SupportChatView(
            viewModel: SupportChatViewModel(
                entryPoint: .helpAndSupport,
                onContactHumanSupport: { _, _, _, _ in }
            )
        )
    }
}

#Preview("Chat") {
    NavigationStack {
        SupportChatView(
            viewModel: SupportChatViewModel(
                entryPoint: .connectivityTool,
                onContactHumanSupport: { _, _, _, _ in }
            )
        )
    }
}
