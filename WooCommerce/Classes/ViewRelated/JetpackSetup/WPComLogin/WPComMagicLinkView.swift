import SwiftUI
import WordPressAuthenticator

/// Hosting controller for `WPComMagicLinkView`
final class WPComMagicLinkHostingController: UIHostingController<WPComMagicLinkView> {

    init(email: String, requiresConnectionOnly: Bool) {
        let viewModel = WPComMagicLinkViewModel(email: email, requiresConnectionOnly: requiresConnectionOnly)
        super.init(rootView: WPComMagicLinkView(viewModel: viewModel))
        rootView.onOpenMail = {
            let linkMailPresenter = LinkMailPresenter(emailAddress: email)
            let appSelector = AppSelector(sourceView: self.view)
            linkMailPresenter.presentEmailClients(on: self, appSelector: appSelector)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }
}


// The magic link screen for the WPCom authentication flow for Jetpack setup.
//
struct WPComMagicLinkView: View {
    private let viewModel: WPComMagicLinkViewModel
    var onOpenMail: () -> Void = {}

    init(viewModel: WPComMagicLinkViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title
                HStack {
                    Text(viewModel.titleString)
                        .largeTitleStyle()
                    Spacer()
                }

                Spacer()

                // Image and instructions
                VStack(spacing: Constants.contentVerticalSpacing) {
                    Image(uiImage: .emailImage)
                        .padding(.bottom)
                    Text(Localization.checkYourEmail)
                        .font(.title3.bold())
                    AttributedText(viewModel.instructionString)
                }

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(Localization.openMail) {
                    ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, tap: .submit))
                    onOpenMail()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPComMagicLinkView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let openMail = NSLocalizedString(
            "Open Mail",
            comment: "Title for the CTA on the magic link screen of the WPCom login flow during Jetpack setup"
        )
        static let checkYourEmail = NSLocalizedString(
            "Check your email on this device!",
            comment: "Message on the magic link screen of the WPCom login flow during Jetpack setup"
        )
    }
}

struct WPComMagicLinkView_Previews: PreviewProvider {
    static var previews: some View {
        WPComMagicLinkView(viewModel: .init(email: "test@example.com", requiresConnectionOnly: true))
    }
}
