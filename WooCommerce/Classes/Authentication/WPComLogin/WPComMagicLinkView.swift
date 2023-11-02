import SwiftUI
import WordPressAuthenticator

/// Hosting controller for `WPComMagicLinkView`
final class WPComMagicLinkHostingController: UIHostingController<WPComMagicLinkView> {

    /// Whether the view is part of the login step of the Jetpack setup flow.
    ///
    private let isJetpackSetup: Bool

    init(email: String, title: String, isJetpackSetup: Bool) {
        self.isJetpackSetup = isJetpackSetup
        let viewModel = WPComMagicLinkViewModel(email: email)
        super.init(rootView: WPComMagicLinkView(title: title,
                                                isJetpackSetup: isJetpackSetup,
                                                viewModel: viewModel))
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent, isJetpackSetup {
            ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, tap: .dismiss))
        }
    }
}


// The magic link screen for the WPCom authentication flow for Jetpack setup.
//
struct WPComMagicLinkView: View {
    /// Title to display on top of the view.
    private let title: String

    /// Whether the view is part of the login step of the Jetpack setup flow.
    private let isJetpackSetup: Bool

    private let viewModel: WPComMagicLinkViewModel
    var onOpenMail: () -> Void = {}

    init(title: String, isJetpackSetup: Bool, viewModel: WPComMagicLinkViewModel) {
        self.title = title
        self.isJetpackSetup = isJetpackSetup
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()
                    .renderedIf(isJetpackSetup)

                // title
                HStack {
                    Text(title)
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
                    if isJetpackSetup {
                        ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, tap: .submit))
                    }
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
        WPComMagicLinkView(title: "Login",
                           isJetpackSetup: false,
                           viewModel: .init(email: "test@example.com"))
    }
}
