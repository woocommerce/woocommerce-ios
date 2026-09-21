import SwiftUI
import Kingfisher

/// Hosting controller for `WPComPasswordLoginView`
final class WPComPasswordLoginHostingController: UIHostingController<WPComPasswordLoginView> {

    private let flow: WPComLoginFlow

    init(title: String,
         flow: WPComLoginFlow,
         viewModel: WPComPasswordLoginViewModel) {
        self.flow = flow
        super.init(rootView: WPComPasswordLoginView(title: title,
                                                    flow: flow,
                                                    viewModel: viewModel))
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent, case .jetpackSetup = flow {
            ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, tap: .dismiss))
        }
    }
}

/// Screen for entering the password for a WPCom account during the Jetpack setup flow
/// This is presented for users authenticated with WPOrg credentials.
struct WPComPasswordLoginView: View {
    @State private var isSecondaryButtonLoading = false
    @FocusState private var isPasswordFieldFocused: Bool
    @ObservedObject private var viewModel: WPComPasswordLoginViewModel

    /// Title to display at the top of the view.
    private let title: String

    private let flow: WPComLoginFlow

    init(title: String,
         flow: WPComLoginFlow,
         viewModel: WPComPasswordLoginViewModel) {
        self.title = title
        self.flow = flow
        self.viewModel = viewModel
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

                // Password field
                AuthenticationFormFieldView(viewModel: .init(
                    header: Localization.passwordLabel,
                    placeholder: Localization.passwordPlaceholder,
                    keyboardType: .default,
                    text: $viewModel.password,
                    isSecure: true,
                    errorMessage: nil,
                    isFocused: isPasswordFieldFocused,
                    autocapitalization: .none
                ))
                .focused($isPasswordFieldFocused)

                // Reset password button
                Button {
                    viewModel.resetPassword()
                } label: {
                    Text(Localization.resetPassword)
                        .linkStyle()
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(Localization.primaryAction) {
                    viewModel.handleLogin()
                    if case .jetpackSetup = flow {
                        ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .password, tap: .submit))
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoggingIn))
                .disabled(viewModel.password.isEmpty)

                // Secondary CTA
                Button(Localization.secondaryAction) {
                    Task { @MainActor in
                        isSecondaryButtonLoading = true
                        await viewModel.requestMagicLink()
                        isSecondaryButtonLoading = false
                    }
                }
                .buttonStyle(SecondaryLoadingButtonStyle(isLoading: isSecondaryButtonLoading))
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPComPasswordLoginView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let passwordLabel = NSLocalizedString(
            "wpcomPasswordLoginView.password",
            value: "Password",
            comment: "Label for the password field on the WPCom password login screen of the Jetpack setup flow."
        )
        static let passwordPlaceholder = NSLocalizedString(
            "wpcomPasswordLoginView.passwordPlaceholder",
            value: "Enter the password for your account",
            comment: "Placeholder text for the password field on the WPCom password login screen of the Jetpack setup flow."
        )
        static let resetPassword = NSLocalizedString(
            "Reset your password",
            comment: "Button to reset password on the WPCom password login screen of the Jetpack setup flow."
        )
        static let primaryAction = NSLocalizedString(
            "Continue",
            comment: "Button to submit password on the WPCom password login screen of the Jetpack setup flow."
        )
        static let secondaryAction = NSLocalizedString(
            "wpcomPasswordLoginView.secondaryAction",
            value: "or continue using a magic link",
            comment: "Button to switch to magic link on the WPCom password login screen of the Jetpack setup flow."
        )
    }
}

struct WPComPasswordLoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPComPasswordLoginView(title: "Connect to WordPress.com",
                               flow: .jetpackSetup(requiresConnectionOnly: true),
                               viewModel: .init(siteURL: "https://example.com",
                                                email: "test@example.com",
                                                onMagicLinkRequest: { _ in },
                                                onMultifactorCodeRequest: { _ in },
                                                onLoginFailure: { _ in },
                                                onLoginSuccess: { _ in }))
    }
}
