import SwiftUI

/// The main chat interface view for AI support.
///
struct SupportChatView: View {
    @Bindable var viewModel: SupportChatViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messageList

            if viewModel.shouldPromptHumanSupport {
                humanSupportBanner
            }

            Divider()

            inputArea
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
        .onAppear {
            viewModel.showGreeting()
            viewModel.resumeIfNeeded()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: SupportChatLayout.messageSpacing) {
                    if viewModel.isResumedChat {
                        resumedChatHeader
                    }

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

// MARK: - Localization
//
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
        static let resumedChatHeader = NSLocalizedString(
            "supportChatView.resumedChatHeader",
            value: "Continuing previous conversation",
            comment: "Inline separator shown at the top of a chat that was opened from history, signalling that prior messages follow"
        )
    }
}

#Preview {
    NavigationStack {
        SupportChatView(
            viewModel: SupportChatViewModel(
                onContactHumanSupport: {}
            )
        )
        .navigationTitle("Chat with Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
