import SwiftUI

/// The main chat interface view for AI support.
///
struct SupportChatView: View {
    @Bindable var viewModel: SupportChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        chatView
            .background(Color(.listBackground))
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                Localization.errorTitle,
                isPresented: .init(
                    get: { viewModel.state != .idle && viewModel.state != .sending },
                    set: { if !$0 { viewModel.dismissError() } }
                ),
                actions: {
                    Button(Localization.ok) {
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

            if viewModel.shouldPromptHumanSupport {
                humanSupportBanner
            } else if viewModel.shouldShowInputArea {
                Divider()

                inputArea
            }
        }
        .onAppear {
            viewModel.showGreeting()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: SupportChatLayout.messageSpacing) {
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
        }
    }

    @ViewBuilder
    private func messageRow(for message: SupportChatViewModel.ChatMessage) -> some View {
        switch message.content {
        case .text(let text):
            SupportChatMessageRow(role: message.role, text: text)

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
                .foregroundStyle(Color(.secondaryLabel))

            ForEach(issues, id: \.self) { issue in
                Button {
                    Task {
                        await viewModel.selectIssue(issue)
                    }
                } label: {
                    Text(issue.displayName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Layout.issueButtonPadding)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.issueButtonRadius))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.selectedIssue != nil)
            }
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SupportChatLayout.bubbleCornerRadius))
        .frame(maxWidth: SupportChatLayout.maxBubbleWidth)
    }

    // MARK: - Diagnostics Progress Bubble

    private func diagnosticsProgressBubble(
        steps: [(test: SupportDiagnosticsService.Test, status: SupportChatViewModel.TestStatus)]
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.resultRowSpacing) {
            ForEach(steps, id: \.test) { step in
                HStack(alignment: .top, spacing: Layout.resultIconSpacing) {
                    statusIcon(for: step.status)
                        .font(.body)

                    Text(step.test.title)
                        .font(.body)
                        .foregroundStyle(step.status == .pending ? Color(.tertiaryLabel) : Color(.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SupportChatLayout.bubbleCornerRadius))
        .frame(maxWidth: SupportChatLayout.maxBubbleWidth)
    }

    private func statusIcon(for status: SupportChatViewModel.TestStatus) -> some View {
        VStack {
            switch status {
            case .pending:
                Image(systemName: "circle")
                    .foregroundStyle(Color(.tertiaryLabel))
            case .running:
                ProgressView()
                    .controlSize(.small)
            case .passed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.red)
            }
        }
        .frame(width: Layout.resultIconSize)
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

            Button {
                viewModel.proceedToChat()
            } label: {
                Text(Localization.continueToChat)
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(Layout.issueButtonPadding)
                    .background(Color.accentColor)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.issueButtonRadius))
            }
            .buttonStyle(.plain)
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Color(.secondarySystemBackground))
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
            } else {
                Button {
                    viewModel.proceedToChat()
                } label: {
                    Text(Localization.continueToChat)
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(Layout.issueButtonPadding)
                        .background(Color(.tertiarySystemBackground))
                        .foregroundStyle(Color(.label))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.issueButtonRadius))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SupportChatLayout.bubblePadding)
        .background(Color(.secondarySystemBackground))
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

    // MARK: - Human Support Banner

    private var humanSupportBanner: some View {
        VStack(spacing: SupportChatLayout.bannerSpacing) {
            Text(Localization.humanSupportMessage)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)

            Button(Localization.contactSupport) {
                viewModel.contactHumanSupport()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
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
        static let issueButtonPadding: CGFloat = 12
        static let issueButtonRadius: CGFloat = 8
        static let progressSpacing: CGFloat = 8
        static let resultsSpacing: CGFloat = 12
        static let resultRowSpacing: CGFloat = 8
        static let resultIconSpacing: CGFloat = 6
        static let resultIconSize: CGFloat = 24
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
        static let ok = NSLocalizedString(
            "supportChatView.ok",
            value: "OK",
            comment: "OK button in support chat error alert"
        )
        static let humanSupportMessage = NSLocalizedString(
            "supportChatView.humanSupportMessage",
            value: "It looks like you might need additional help. Would you like to contact our support team?",
            comment: "Message shown when the bot suggests contacting human support"
        )
        static let contactSupport = NSLocalizedString(
            "supportChatView.contactSupport",
            value: "Contact Support",
            comment: "Button to contact human support from the chat"
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
            value: "All checks completed with no issues",
            comment: "Message shown when all diagnostic checks pass"
        )
    }
}

#Preview("Issue Picker") {
    NavigationStack {
        SupportChatView(
            viewModel: SupportChatViewModel(
                entryPoint: .helpAndSupport,
                onContactHumanSupport: { _ in }
            )
        )
    }
}

#Preview("Chat") {
    NavigationStack {
        SupportChatView(
            viewModel: SupportChatViewModel(
                entryPoint: .connectivityTool,
                onContactHumanSupport: { _ in }
            )
        )
    }
}
