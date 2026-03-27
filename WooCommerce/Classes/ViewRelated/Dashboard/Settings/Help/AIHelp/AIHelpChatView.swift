import SwiftUI

/// Chat-like interface for AI-powered help and troubleshooting.
///
struct AIHelpChatView: View {

    @Bindable var viewModel: AIHelpChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            siteInfoHeader
            Divider()
            messageList
            Divider()
            bottomArea
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Site Info Header
//
private extension AIHelpChatView {
    var siteInfoHeader: some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            Text(viewModel.siteName)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(viewModel.siteURL)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.headerPadding)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Message List
//
private extension AIHelpChatView {
    var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Constants.messageSpacing) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(for: message)
                            .id(message.id)
                    }
                }
                .padding(Constants.messagePadding)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func messageBubble(for message: AIHelpChatMessage) -> some View {
        switch message.role {
        case .user:
            userBubble(message)
        case .system:
            systemBubble(message)
        case .diagnosticResult:
            diagnosticBubble(message)
        }
    }

    func userBubble(_ message: AIHelpChatMessage) -> some View {
        HStack {
            Spacer(minLength: Constants.bubbleMinSpacing)
            Text(message.content)
                .padding(Constants.bubbleContentPadding)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Constants.bubbleCornerRadius))
        }
    }

    func systemBubble(_ message: AIHelpChatMessage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Constants.bubbleInternalSpacing) {
                if message.diagnosticStatus == .loading {
                    HStack(spacing: Constants.loadingSpacing) {
                        ProgressView()
                        Text(message.content)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(message.content)
                }
            }
            .padding(Constants.bubbleContentPadding)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: Constants.bubbleCornerRadius))
            Spacer(minLength: Constants.bubbleMinSpacing)
        }
    }

    func diagnosticBubble(_ message: AIHelpChatMessage) -> some View {
        VStack(alignment: .leading, spacing: Constants.bubbleInternalSpacing) {
            HStack(spacing: Constants.diagnosticIconSpacing) {
                diagnosticIcon(for: message.diagnosticStatus)
                Text(message.content)
                    .font(.subheadline)
            }

            if !message.actions.isEmpty {
                ForEach(message.actions) { action in
                    Button(action.title) {
                        viewModel.performAction(action)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.bubbleContentPadding)
        .background(diagnosticBackground(for: message.diagnosticStatus))
        .clipShape(RoundedRectangle(cornerRadius: Constants.bubbleCornerRadius))
    }

    @ViewBuilder
    func diagnosticIcon(for status: AIHelpChatMessage.DiagnosticStatus?) -> some View {
        switch status {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .loading:
            ProgressView()
        case .none:
            EmptyView()
        }
    }

    func diagnosticBackground(for status: AIHelpChatMessage.DiagnosticStatus?) -> Color {
        switch status {
        case .success:
            return Color.green.opacity(Constants.diagnosticBackgroundOpacity)
        case .failure:
            return Color.red.opacity(Constants.diagnosticBackgroundOpacity)
        case .warning:
            return Color.orange.opacity(Constants.diagnosticBackgroundOpacity)
        case .loading, .none:
            return Color(.systemGray6)
        }
    }
}

// MARK: - Bottom Area
//
private extension AIHelpChatView {
    @ViewBuilder
    var bottomArea: some View {
        switch viewModel.phase {
        case .selectTopic:
            topicSelectionView
        case .collectingDetails:
            textInputView
        case .offeringEscalation:
            escalationView
        case .runningDiagnostics, .aiAnalyzing:
            EmptyView()
        }
    }

    var topicSelectionView: some View {
        ScrollView {
            LazyVStack(spacing: Constants.topicButtonSpacing) {
                ForEach(AIHelpTroubleshootingOption.allCases) { option in
                    Button {
                        viewModel.selectTopic(option)
                    } label: {
                        Text(option.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Constants.topicButtonPadding)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.topicButtonCornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Constants.bottomAreaPadding)
        }
        .frame(maxHeight: Constants.topicListMaxHeight)
    }

    var textInputView: some View {
        HStack(spacing: Constants.inputSpacing) {
            TextField(Localization.inputPlaceholder, text: $viewModel.userInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(viewModel.isProcessing)

            Button {
                viewModel.submitUserInput()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isProcessing)
        }
        .padding(Constants.bottomAreaPadding)
    }

    var escalationView: some View {
        VStack(spacing: Constants.escalationSpacing) {
            Text(Localization.escalationPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(Localization.contactSupport) {
                viewModel.fileZendeskTicket()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Constants.bottomAreaPadding)
    }
}

// MARK: - Constants
//
private extension AIHelpChatView {
    enum Constants {
        static let headerSpacing: CGFloat = 4
        static let headerPadding: CGFloat = 12
        static let messageSpacing: CGFloat = 12
        static let messagePadding: CGFloat = 16
        static let bubbleMinSpacing: CGFloat = 60
        static let bubbleContentPadding: CGFloat = 12
        static let bubbleCornerRadius: CGFloat = 12
        static let bubbleInternalSpacing: CGFloat = 8
        static let loadingSpacing: CGFloat = 8
        static let diagnosticIconSpacing: CGFloat = 8
        static let diagnosticBackgroundOpacity: CGFloat = 0.1
        static let topicButtonSpacing: CGFloat = 8
        static let topicButtonPadding: CGFloat = 12
        static let topicButtonCornerRadius: CGFloat = 8
        static let topicListMaxHeight: CGFloat = 300
        static let bottomAreaPadding: CGFloat = 16
        static let inputSpacing: CGFloat = 8
        static let escalationSpacing: CGFloat = 12
    }
}

// MARK: - Localization
//
private extension AIHelpChatView {
    enum Localization {
        static let title = NSLocalizedString(
            "aiHelp.chat.title",
            value: "Troubleshoot with AI",
            comment: "Navigation title for the AI Help chat screen"
        )
        static let inputPlaceholder = NSLocalizedString(
            "aiHelp.chat.inputPlaceholder",
            value: "Describe your issue...",
            comment: "Placeholder text in the chat input field"
        )
        static let escalationPrompt = NSLocalizedString(
            "aiHelp.chat.escalationPrompt",
            value: "Still need help? Our support team is here for you.",
            comment: "Message shown above the Contact Support button"
        )
        static let contactSupport = NSLocalizedString(
            "aiHelp.chat.contactSupportButton",
            value: "Contact Support",
            comment: "Button to file a Zendesk support ticket from AI Help"
        )
    }
}
