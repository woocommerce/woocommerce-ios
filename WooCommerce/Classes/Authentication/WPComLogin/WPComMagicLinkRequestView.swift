import SwiftUI
import Kingfisher

final class WPComMagicLinkRequestHostingController: UIHostingController<WPComMagicLinkRequestView> {
    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title: String,
         flow: WPComLoginFlow,
         viewModel: WPComMagicLinkRequestViewModel) {
        let view = WPComMagicLinkRequestView(title: title,
                                             flow: flow,
                                             viewModel: viewModel)
        super.init(rootView: view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }
}

struct WPComMagicLinkRequestView: View {
    @StateObject private var viewModel: WPComMagicLinkRequestViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Title to display at the top of the view.
    private let title: String

    let flow: WPComLoginFlow

    init(title: String,
         flow: WPComLoginFlow,
         viewModel: WPComMagicLinkRequestViewModel) {
        self.title = title
        self.flow = flow
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                switch flow {
                case .jetpackSetup:
                    JetpackInstallHeaderView()
                }

                // Title
                Text(title)
                    .largeTitleStyle()
                    .bold()

                // Avatar and email
                WPComLoginGravatarView(email: viewModel.email, gravatarURL: viewModel.avatarURL)

                Text(Localization.label)
                    .bodyStyle()

                Spacer()

                if dynamicTypeSize.isAccessibilitySize {
                    footer
                }
            }
            .padding(Constants.contentPadding)
        }.safeAreaInset(edge: .bottom) {
            footer
                .padding(Constants.contentPadding)
                .background(Color(uiColor: .systemBackground))
                .renderedIf(!dynamicTypeSize.isAccessibilitySize)
        }
    }

    private var footer: some View {
        VStack {
            Button(Localization.sendLinkButton) {
                Task {
                    await viewModel.sendMagicLink()
                }
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoading))

            Button(Localization.fallbackButton) {
                viewModel.useUsernamePassword()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

private extension WPComMagicLinkRequestView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let label = NSLocalizedString(
            "wpcomMagicLinkRequestView.label",
            value: "We'll email you a link that'll log you in instantly, no password needed.",
            comment: "A message that informs the user that a magic link will be sent to their email address."
        )
        static let sendLinkButton = NSLocalizedString(
            "wpcomMagicLinkRequestView.primaryAction",
            value: "Send link by email",
            comment: "Button title for the action of sending a magic link email to log in to WordPress.com."
        )
        // For now this is hardcoded for the username/password fallback, if we need to support email/password in the future,
        // we can add a  way to configure the fallback action.
        static let fallbackButton = NSLocalizedString(
            "wpcomMagicLinkRequestView.useUsernamePassword",
            value: "Use username and password",
            comment: "Button title for the action of signing in using WordPress.com username and password."
        )
    }
}


#Preview {
    WPComMagicLinkRequestView(title: "Connect to WordPress.com",
                              flow: .jetpackSetup(requiresConnectionOnly: true),
                              viewModel: WPComMagicLinkRequestViewModel(email: "test@example.com",
                                                                        onMagicLinkSent: { _ in },
                                                                        onUseUsernamePassword: {},
                                                                        onError: { _ in })
    )
}
