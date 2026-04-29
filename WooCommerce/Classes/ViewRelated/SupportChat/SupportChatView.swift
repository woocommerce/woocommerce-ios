import SwiftUI

/// The main chat interface view for AI support.
///
struct SupportChatView: View {
    @Bindable var viewModel: SupportChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        Group {
            switch viewModel.phase {
            case .issuePicker:
                issuePickerView
            case .runningDiagnostics:
                diagnosticsProgressView
            case .showingResults:
                resultsView
            case .chatting:
                chatView
            }
        }
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

    // MARK: - Issue Picker

    private var issuePickerView: some View {
        List {
            Section {
                ForEach(SupportIssueType.allCases, id: \.self) { issue in
                    Button {
                        Task {
                            await viewModel.selectIssue(issue)
                        }
                    } label: {
                        Text(issue.displayName)
                            .foregroundStyle(Color(.label))
                    }
                }
            } header: {
                Text(Localization.issuePickerHeader)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Diagnostics Progress

    private var diagnosticsProgressView: some View {
        VStack(spacing: Layout.progressSpacing) {
            ProgressView()
                .scaleEffect(Layout.progressScale)

            Text(Localization.runningDiagnostics)
                .font(.headline)

            if let issue = viewModel.selectedIssue {
                Text(issue.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: Layout.resultsSpacing) {
                ForEach(viewModel.diagnosticResults, id: \.test) { result in
                    resultCard(for: result)
                }

                proceedToChatButton
            }
            .padding()
        }
    }

    private func resultCard(for result: SupportDiagnosticsService.Result) -> some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            HStack {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.isSuccess ? Color.green : Color.red)

                Text(result.test.title)
                    .font(.headline)

                Spacer()
            }

            if !result.isSuccess {
                if let errorMessage = result.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
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
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
    }

    private var proceedToChatButton: some View {
        Button {
            viewModel.proceedToChat()
        } label: {
            Text(Localization.continueToChat)
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top)
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            messageList

            if viewModel.shouldPromptHumanSupport {
                humanSupportBanner
            } else {
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
                LazyVStack(spacing: SupportChatLayout.messageSpacing) {
                    ForEach(viewModel.messages) { message in
                        SupportChatMessageRow(message: message)
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
        static let progressSpacing: CGFloat = 16
        static let progressScale: CGFloat = 1.5
        static let resultsSpacing: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let cardCornerRadius: CGFloat = 12
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
            value: "What are you having trouble with?",
            comment: "Header for the issue picker in support chat"
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
