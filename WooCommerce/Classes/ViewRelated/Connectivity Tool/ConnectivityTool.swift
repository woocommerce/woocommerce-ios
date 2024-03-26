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

        // Listen to the contact support button
        rootView.onContactSupportTapped = { [weak self] in
            self?.showContactSupportForm()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showContactSupportForm() {
        let supportController = SupportFormHostingController(viewModel: .init())
        supportController.show(from: self)

        ServiceLocator.analytics.track(event: .ConnectivityTool.contactSupportTapped())
    }
}

/// View for the Connectivity Tool.
///
struct ConnectivityTool: View {

    /// Dependency object.
    ///
    struct Card {
        let title: String
        let icon: ConnectivityToolCard.Icon
        let state: ConnectivityToolCard.State
    }

    /// Tool cards.
    ///
    var cards: [Card]

    /// Closure to be invoked when the "Contact Support" button is tapped.
    ///
    var onContactSupportTapped: (() -> ())?

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {

            Spacer()

            Text(Localization.subtitle)
                .secondaryBodyStyle()

            ScrollView {
                ForEach(cards, id: \.title) { card in
                    ConnectivityToolCard(icon: card.icon, title: card.title, state: card.state)
                }
            }
            .padding(.horizontal)

            Divider().ignoresSafeArea()

            Button(Localization.contactSupport) {
                onContactSupportTapped?()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding()
        }
        .background(Color(uiColor: .listBackground))
    }
}

private extension ConnectivityTool {
    enum Localization {
        static let subtitle = NSLocalizedString("Please wait while we attempt to identify your connection issue.",
                                                comment: "Subtitle on the connectivity tool screen")
        static let contactSupport = NSLocalizedString("Contact Support",
                                                      comment: "Contact support button in the connectivity tool screen")
    }
}

/// Reusable connectivity card.
///
struct ConnectivityToolCard: View {

    /// Represents the state of the card.
    ///
    enum State {

        /// Represents an action to could be performed when presenting an error.
        ///
        struct ErrorAction {
            let title: String
            let action: () -> ()
        }

        case inProgress
        case success
        case error(String, ErrorAction?)

        /// Builds the icon based on the state
        ///
        @ViewBuilder func buildIcon() -> some View {
            switch self {
            case .inProgress:
                ProgressView()
            case .success:
                Image(uiImage: .checkCircleImage)
                    .environment(\.colorScheme, .light)
            case .error:
                Image(uiImage: .checkPartialCircleImage.withRenderingMode(.alwaysTemplate))
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

        /// Builds the asset based on the icon
        ///
        func buildAsset() -> Image {
            switch self {
            case .system(let name):
                return Image(systemName: name)
            case .uiImage(let uiImage):
                return Image(uiImage: uiImage)
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
    let state: State

    /// Internal layout values
    ///
    @ScaledMetric private var iconSize = 40.0
    private static let cornerRadius = 4.0
    private static let verticalSpacing = 16.0
    private static let cardSpacing = 8.0

    var body: some View {
        VStack(spacing: Self.verticalSpacing) {
            HStack {

                Circle()
                    .fill(Color(uiColor: .listBackground))
                    .overlay {
                        icon.buildAsset()
                            .foregroundColor(Color(uiColor: .primary))
                    }
                    .frame(width: iconSize, height: iconSize)

                Text(title)
                    .bodyStyle()

                Spacer()

                state.buildIcon()
            }

            if case let .error(message, buttonAction) = state {
                Text(message)
                    .foregroundColor(Color(uiColor: .error))
                    .subheadlineStyle()
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let buttonAction {
                    Button(buttonAction.title, action: buttonAction.action)
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(uiColor: .listForeground(modal: false)))
        .cornerRadius(Self.cornerRadius)
        .padding(.horizontal)
        .padding(.vertical, Self.cardSpacing)

    }
}

#Preview("Tool") {
    NavigationView {
        ConnectivityTool(cards: [
            .init(title: "Internet Connection", icon: .system("wifi"), state: .success),
            .init(title: "WordPress.com servers", icon: .system("server.rack"), state: .success),
            .init(title: "Your Site",
                  icon: .system("storefront"),
                  state: .error("Your site is not responding properly\nPlease reach out to your host for further assistance",
                    .init(title: "Read More", action: {}))),
            .init(title: "Your site orders", icon: .system("list.clipboard"), state: .inProgress)
        ])
            .navigationTitle("Connectivity Test")
            .navigationBarTitleDisplayMode(.inline)
    }
}
