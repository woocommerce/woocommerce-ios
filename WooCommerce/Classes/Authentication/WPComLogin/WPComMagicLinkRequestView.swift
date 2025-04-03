import SwiftUI
import Kingfisher

class WPComMagicLinkRequestHostingController: UIHostingController<WPComMagicLinkRequestView> {
    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title: String,
         viewModel: WPComMagicLinkRequestViewModel) {
        let view = WPComMagicLinkRequestView(title: title,
                                             viewModel: viewModel)
        super.init(rootView: view)
    }
}

struct WPComMagicLinkRequestView: View {
    @ObservedObject private var viewModel: WPComMagicLinkRequestViewModel

    /// Title to display at the top of the view.
    private let title: String

    init(title: String,
         viewModel: WPComMagicLinkRequestViewModel) {
        self.title = title
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // Title
                Text(title)
                    .largeTitleStyle()

                // Avatar and email
                WPComLoginGravatarView(email: viewModel.email, gravatarURL: viewModel.avatarURL)

                Text(Localization.label)
                    .bodyStyle()

                Spacer()
            }
            .padding(Constants.contentPadding)
        }.safeAreaInset(edge: .bottom) {
            VStack {
                Button(Localization.sendLinkButton) {
                    viewModel.sendMagicLink()
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoading))

                Button(Localization.fallbackButton) {
                    // TODO: handle fallback action
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
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
            comment: "Button title for the action of logging in with a password."
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
    WPComMagicLinkRequestView(title: "Connect Jetpack",
                              viewModel: WPComMagicLinkRequestViewModel(email: "test@example.com",
                                                                        onMagicLinkSent: { _ in },
                                                                        onError: { _ in })
    )
}
