import SwiftUI
import Combine

/// Connectivity Tool Hosting Controller
///
final class ConnectivityToolViewController: UIHostingController<ConnectivityTool> {

    /// ConnectivityTool view model
    ///
    private let viewModel: ConnectivityToolViewModel

    /// Combine subscriptions
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// Retains the Jetpack setup coordinator while the flow is active.
    ///
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?

    /// Retains the support escalation coordinator while the flow is active.
    ///
    private var supportEscalationCoordinator: SupportEscalationCoordinator?

    init() {
        viewModel = ConnectivityToolViewModel()
        let view = ConnectivityTool(cards: viewModel.cards)
        super.init(rootView: view)
        self.hidesBottomBarWhenPushed = true
        self.title = NSLocalizedString("Troubleshoot Connection", comment: "Screen title for the connectivity tool")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Bind cards to view
        viewModel.$cards.sink { [weak self] cards in
            self?.rootView.cards = cards
        }
        .store(in: &subscriptions)

        // Bind chat button visibility
        viewModel.$showChatButton.sink { [weak self] show in
            self?.rootView.showChatButton = show
        }
        .store(in: &subscriptions)

        // Bind contact support button visibility
        viewModel.$showContactSupportButton.sink { [weak self] show in
            self?.rootView.showContactSupportButton = show
        }
        .store(in: &subscriptions)

        // Open selected URL — system URLs (e.g. notification settings) via UIApplication,
        // web URLs in-app using Safari.
        viewModel.$selectedURL
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                guard let self else { return }
                self.viewModel.selectedURL = nil
                if url.scheme == "http" || url.scheme == "https" {
                    WebviewHelper.launch(url, with: self)
                } else {
                    UIApplication.shared.open(url)
                }
            }
            .store(in: &subscriptions)

        // Start Jetpack setup when requested
        viewModel.$shouldStartJetpackSetup
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.viewModel.shouldStartJetpackSetup = false
                self?.startJetpackSetup()
            }
            .store(in: &subscriptions)

        // Listen to the contact support button
        rootView.onContactSupportTapped = { [weak self] in
            self?.showContactSupportForm()
        }

        // Listen to the chat with support button
        rootView.onChatWithSupportTapped = { [weak self] in
            self?.showSupportChat()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startJetpackSetup() {
        guard let site = viewModel.stores.sessionManager.defaultSite else { return }
        let coordinator = JetpackSetupCoordinator(site: site, rootViewController: self, onCompletion: { [weak self] in
            self?.viewModel.retryTest(.notifications)
            self?.jetpackSetupCoordinator = nil
        })
        jetpackSetupCoordinator = coordinator
        coordinator.startSetup()
    }

    private func showContactSupportForm(sourceTag: String? = nil,
                                        additionalTags: [String] = [],
                                        chatTranscript: String? = nil,
                                        preselectedArea: SupportFormViewModel.Area? = nil) {
        var attachments: [ZendeskAttachment] = []

        if let troubleshootingDescription = viewModel.troubleshootingDescription(),
           let data = troubleshootingDescription.data(using: .utf8) {
            attachments.append(ZendeskAttachment(
                data: data,
                filename: "connectivitytest_log.txt",
                contentType: "text/plain"
            ))
        }

        if let transcript = chatTranscript,
           !transcript.isEmpty,
           let data = transcript.data(using: .utf8) {
            attachments.append(ZendeskAttachment(
                data: data,
                filename: "support_chat_transcript.txt",
                contentType: "text/plain"
            ))
        }

        let supportController = SupportFormHostingController(viewModel: SupportFormViewModel(
            sourceTag: sourceTag,
            additionalTags: additionalTags,
            attachments: attachments,
            preselectedArea: preselectedArea
        ))
        supportController.show(from: self)

        ServiceLocator.analytics.track(event: .ConnectivityTool.contactSupportTapped())
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
                                           entryPoint: SupportChatViewModel.EntryPoint,
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
        guard let troubleshootingDescription = viewModel.troubleshootingDescription(),
              let data = troubleshootingDescription.data(using: .utf8) else {
            return []
        }
        return [ZendeskAttachment(
            data: data,
            filename: "connectivitytest_log.txt",
            contentType: "text/plain"
        )]
    }
}

/// View for the Connectivity Tool.
///
struct ConnectivityTool: View {

    /// Dependency object.
    ///
    struct Card {
        let testCase: ConnectivityToolViewModel.ConnectivityTest?
        let title: String
        let icon: ConnectivityToolCard.Icon
        let state: ConnectivityToolCard.ConnectivityState

        init(testCase: ConnectivityToolViewModel.ConnectivityTest? = nil,
             title: String,
             icon: ConnectivityToolCard.Icon,
             state: ConnectivityToolCard.ConnectivityState) {
            self.testCase = testCase
            self.title = title
            self.icon = icon
            self.state = state
        }
    }

    /// Tool cards.
    ///
    var cards: [Card]

    /// Closure to be invoked when the "Contact Support" button is tapped.
    ///
    var onContactSupportTapped: (() -> ())?

    /// Closure to be invoked when the "Chat with Support" button is tapped.
    ///
    var onChatWithSupportTapped: (() -> ())?

    /// Whether the chat button should be shown.
    ///
    var showChatButton: Bool = false

    /// Whether the contact support button should be shown.
    ///
    var showContactSupportButton: Bool = false

    /// Internal layout values
    ///
    private static let dividerVerticalSpacing = 8.0

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {

            Spacer()

            ScrollView {

                Text(Localization.subtitle)
                    .bodyStyle(opacity: 0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                ForEach(cards, id: \.title) { card in
                    ConnectivityToolCard(icon: card.icon, title: card.title, state: card.state)
                        .padding(.horizontal)

                    Divider()
                        .padding(.leading)
                        .padding(.vertical, Self.dividerVerticalSpacing)
                }
            }

            Divider().ignoresSafeArea()

            if showChatButton {
                Button(Localization.chatWithSupport) {
                    onChatWithSupportTapped?()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            } else if showContactSupportButton {
                Button(Localization.contactSupport) {
                    onContactSupportTapped?()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding()
            }
        }
        .background(Color(uiColor: .listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ConnectivityTool {
    enum Localization {
        static let subtitle = NSLocalizedString("Please wait while we attempt to identify your connection issue.",
                                                comment: "Subtitle on the connectivity tool screen")
        static let contactSupport = NSLocalizedString("Contact Support",
                                                      comment: "Contact support button in the connectivity tool screen")
        static let chatWithSupport = NSLocalizedString(
            "connectivityTool.chatWithSupport",
            value: "Chat with Support",
            comment: "Button to open AI chat support in the connectivity tool screen"
        )
        static let title = NSLocalizedString(
            "connectivityTool.title",
            value: "Troubleshoot Connection",
            comment: "Screen title for the connectivity tool"
        )
    }
}

/// Reusable connectivity card.
///
struct ConnectivityToolCard: View {

    /// Represents the state of the card.
    ///
    enum ConnectivityState {

        /// Represents an action to could be performed when presenting an error.
        ///
        struct Action {
            let id: String?
            let title: String
            let systemImage: String
            let action: () -> ()
            let technicalDetails: String?

            init(id: String? = nil,
                 title: String,
                 systemImage: String,
                 action: @escaping () -> Void = {},
                 technicalDetails: String? = nil) {
                self.id = id
                self.title = title
                self.systemImage = systemImage
                self.action = action
                self.technicalDetails = technicalDetails
            }
        }

        case inProgress
        case success
        case empty(String)
        case error(String, [Action])

        /// Builds the icon based on the state
        ///
        @ViewBuilder func buildIcon() -> some View {
            switch self {
            case .inProgress:
                ProgressView()
            case .success:
                Image(uiImage: .checkCircleImage)
                    .environment(\.colorScheme, .light)
            case .empty:
                EmptyView()
            case .error:
                Image(uiImage: .exclamationFilledImage)
                    .foregroundColor(Color.init(uiColor: .error))
            }
        }

        /// Determines if the test was successful or not.
        ///
        var isSuccess: Bool {
            switch self {
            case .success:
                return true
            default:
                return false
            }
        }
    }

    /// Represents the icon of the card
    ///
    enum Icon {
        case system(String)
        case uiImage(UIImage)
        case empty

        /// Builds the asset based on the icon
        ///
        @ViewBuilder func buildAsset() -> some View {
            switch self {
            case .system(let name):
                Image(systemName: name)
            case .uiImage(let uiImage):
                Image(uiImage: uiImage)
            case .empty:
                EmptyView()
            }
        }
    }

    /// Card icon
    ///
    let icon: Icon

    /// Card title
    ///
    let title: String

    /// Card state
    ///
    let state: ConnectivityState

    /// Internal layout values
    ///
    private static let verticalSpacing = 16.0
    private static let iconSize = 24.0

    @State private var selectedTechnicalDetails: TechnicalDetailsItem?

    init(icon: Icon, title: String, state: ConnectivityState) {
        self.icon = icon
        self.title = title
        self.state = state
    }

    var body: some View {
        VStack(spacing: Self.verticalSpacing) {
            HStack {

                icon.buildAsset()
                    .foregroundColor(Color(uiColor: .text))
                    .frame(width: Self.iconSize, height: Self.iconSize)

                Text(title)
                    .bodyStyle()
                    .bold()

                Spacer()

                state.buildIcon()
            }

            switch state {
            case .empty(let message):
                cardMessage(message)

            case let .error(message, actions):
                cardMessage(message)

                ForEach(actions, id: \.title) { action in
                    Button(action.title, systemImage: action.systemImage) {
                        if let technicalDetails = action.technicalDetails {
                            selectedTechnicalDetails = TechnicalDetailsItem(details: technicalDetails)
                        } else {
                            action.action()
                        }
                    }
                    .foregroundColor(Color(uiColor: .accent))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            default:
                EmptyView()
            }
        }
        .sheet(item: $selectedTechnicalDetails) { item in
            TechnicalDetailsView(technicalDetails: item.details)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder func cardMessage(_ message: String) -> some View {
        Text(message)
            .foregroundColor(Color(uiColor: .text))
            .subheadlineStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Tool") {
    NavigationView {
        ConnectivityTool(cards: [
            .init(title: "Internet Connection", icon: .system("wifi"), state: .success),
            .init(title: "Connecting to WordPress.com servers", icon: .system("server.rack"), state: .success),
            .init(title: "Connecting to your site",
                  icon: .system("storefront"),
                  state: .error("Your site is taking too long to respond.\n\nPlease contact your hosting provider for further assistance.",
                    [.init(title: "Retry connection", systemImage: "arrow.clockwise", action: {}),
                     .init(title: "Read More", systemImage: "arrow.up.forward.app", action: {})])),
            .init(title: "Fetching your site orders", icon: .system("list.clipboard"), state: .inProgress),
            .init(title: "No connection issues", icon: .empty, state: .empty("If your data still isn't loading, contact our support team for assistance."))
        ])
            .navigationTitle("Connectivity Test")
            .navigationBarTitleDisplayMode(.inline)
    }
}
