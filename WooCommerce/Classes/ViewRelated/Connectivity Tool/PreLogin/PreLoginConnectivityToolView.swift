import SwiftUI

// MARK: - Hosting Controller

/// Presents the pre-login connectivity tool.
///
final class PreLoginConnectivityToolViewController: UIHostingController<PreLoginConnectivityToolView> {

    private let viewModel: PreLoginConnectivityToolViewModel

    /// Retains the support escalation coordinator while the flow is active.
    private var supportEscalationCoordinator: SupportEscalationCoordinator?

    init(siteURL: URL) {
        viewModel = PreLoginConnectivityToolViewModel(siteURL: siteURL)
        let view = PreLoginConnectivityToolView(viewModel: viewModel)
        super.init(rootView: view)
        self.hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        rootView.onContactSupportTapped = { [weak self] in
            self?.showContactSupportForm()
        }

        rootView.onChatWithSupportTapped = { [weak self] in
            self?.showSupportChat()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showContactSupportForm() {
        let supportController = SupportFormHostingController(viewModel: SupportFormViewModel(
            attachments: buildTroubleshootingAttachment()
        ))
        supportController.show(from: self)
    }

    private func showSupportChat() {
        var viewModelHolder: SupportChatViewModel?
        let chatViewModel = viewModel.makeSupportChatViewModel { [weak self] chatID, transcript, supportAreaInfo, entryPoint in
            self?.navigationController?.popViewController(animated: true)
            self?.handleContactHumanSupport(chatID: chatID,
                                            transcript: transcript,
                                            supportAreaInfo: supportAreaInfo,
                                            entryPoint: entryPoint,
                                            onTicketCreated: { [weak viewModelHolder] in
                                                viewModelHolder?.markChatTicketCreated()
                                            })
        }
        viewModelHolder = chatViewModel

        let chatController = SupportChatHostingController(viewModel: chatViewModel)
        chatController.show(from: self)
    }

    private func handleContactHumanSupport(chatID: Int64?,
                                           transcript: String,
                                           supportAreaInfo: SupportAreaInfo?,
                                           entryPoint: String,
                                           onTicketCreated: @escaping () -> Void) {
        supportEscalationCoordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            additionalAttachmentsProvider: { [weak self] in
                self?.buildTroubleshootingAttachment() ?? []
            },
            onTicketCreated: onTicketCreated
        )
        supportEscalationCoordinator?.handleEscalation(chatID: chatID, transcript: transcript, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint)
    }

    private func buildTroubleshootingAttachment() -> [ZendeskAttachment] {
        guard let description = viewModel.troubleshootingDescription(),
              let data = description.data(using: .utf8) else {
            return []
        }
        return [ZendeskAttachment(
            data: data,
            filename: "prelogin_connectivitytest_log.md",
            contentType: "text/markdown"
        )]
    }
}

// MARK: - Main View

struct PreLoginConnectivityToolView: View {

    @ObservedObject var viewModel: PreLoginConnectivityToolViewModel

    /// Closure invoked when the "Contact Support" button is tapped.
    var onContactSupportTapped: (() -> Void)?

    /// Closure invoked when the "Chat with AI Support" button is tapped.
    var onChatWithSupportTapped: (() -> Void)?

    var body: some View {
        VStack(spacing: .zero) {
            ScrollView {
                Text(String.localizedStringWithFormat(Localization.subtitle, viewModel.siteURL.absoluteString))
                    .secondaryBodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(viewModel.cards) { card in
                    PreLoginCheckCardView(card: card)
                        .padding(.horizontal)

                    Divider()
                        .padding(.leading)
                        .padding(.vertical)
                }
            }

            if viewModel.showChatButton {
                Button(Localization.chatWithSupport) {
                    onChatWithSupportTapped?()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding()
            } else if viewModel.showContactSupportButton {
                Button(Localization.contactSupport) {
                    onContactSupportTapped?()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding()
            }
        }
        .background(Color(uiColor: .listForeground(modal: false)))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.startConnectivityTests()
        }
    }
}

// MARK: - Card View

private struct PreLoginCheckCardView: View {

    let card: PreLoginCheckCard

    @State private var selectedDiagnosticLog: TechnicalDetailsItem?
    @ScaledMetric private var scale = 1.0

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            HStack {
                card.icon.buildAsset()
                    .foregroundColor(Color(uiColor: .text))
                    .frame(width: Layout.iconSize * scale, height: Layout.iconSize * scale)

                Text(card.title)
                    .bodyStyle()
                    .bold()

                Spacer()

                stateIndicator
            }

            switch card.state {
            case .success(let summary):
                Text(summary)
                    .foregroundColor(Color(uiColor: .text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

            case .error(let summary):
                Text(summary)
                    .foregroundColor(Color(uiColor: .text))
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

                if card.diagnosticLog != nil {
                    Button(Localization.viewDetails, systemImage: "info.circle") {
                        selectedDiagnosticLog = TechnicalDetailsItem(details: card.diagnosticLog ?? "")
                    }
                    .foregroundColor(Color(uiColor: .accent))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            case .inProgress:
                EmptyView()
            }
        }
        .sheet(item: $selectedDiagnosticLog) { item in
            TechnicalDetailsView(technicalDetails: item.details)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch card.state {
        case .inProgress:
            ProgressView()
        case .success:
            Image(uiImage: .checkCircleImage)
                .environment(\.colorScheme, .light)
        case .error:
            Image(uiImage: .exclamationFilledImage)
                .foregroundColor(Color(uiColor: .error))
        }
    }

    private enum Layout {
        static let iconSize: CGFloat = 24
        static let verticalSpacing: CGFloat = 16
    }

    private enum Localization {
        static let viewDetails = NSLocalizedString(
            "preLoginConnectivityToolView.viewDetails",
            value: "View details",
            comment: "Button to view technical diagnostic details for a failed connectivity check"
        )
    }
}

// MARK: - Localization

private extension PreLoginConnectivityToolView {
    enum Localization {
        static let title = NSLocalizedString(
            "preLoginConnectivityToolView.title",
            value: "Site Compatibility",
            comment: "Navigation title for the pre-login connectivity tool"
        )
        static let subtitle = NSLocalizedString(
            "preLoginConnectivityToolView.subtitle",
            value: "Checking your site %1$@ for compatibility with the WooCommerce app.",
            comment: "Subtitle on the pre-login connectivity tool screen. The placeholder is the site address"
        )
        static let contactSupport = NSLocalizedString(
            "preLoginConnectivityToolView.contactSupport",
            value: "Contact Support",
            comment: "Contact support button in the pre-login connectivity tool"
        )
        static let chatWithSupport = NSLocalizedString(
            "preLoginConnectivityToolView.chatWithSupport",
            value: "Chat with Support",
            comment: "Chat with AI support button in the pre-login connectivity tool"
        )
    }
}
