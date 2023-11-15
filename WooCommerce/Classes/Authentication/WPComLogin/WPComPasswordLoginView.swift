import SwiftUI
import Kingfisher

/// Hosting controller for `WPComPasswordLoginView`
final class WPComPasswordLoginHostingController: UIHostingController<WPComPasswordLoginView> {

    /// Whether the view is part of the login step of the Jetpack setup flow.
    private let isJetpackSetup: Bool

    init(title: String,
         isJetpackSetup: Bool,
         viewModel: WPComPasswordLoginViewModel) {
        self.isJetpackSetup = isJetpackSetup
        super.init(rootView: WPComPasswordLoginView(title: title,
                                                    isJetpackSetup: isJetpackSetup,
                                                    viewModel: viewModel))
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

/// Screen for entering the password for a WPCom account during the Jetpack setup flow
/// This is presented for users authenticated with WPOrg credentials.
struct WPComPasswordLoginView: View {
    @State private var isSecondaryButtonLoading = false
    @FocusState private var isPasswordFieldFocused: Bool
    @ObservedObject private var viewModel: WPComPasswordLoginViewModel

    /// Title to display at the top of the view.
    private let title: String

    /// Whether the view is part of the login step of the Jetpack setup flow.
    private let isJetpackSetup: Bool

    init(title: String,
         isJetpackSetup: Bool = false,
         viewModel: WPComPasswordLoginViewModel) {
        self.title = title
        self.isJetpackSetup = isJetpackSetup
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()
                    .renderedIf(isJetpackSetup)

                // Title
                Text(title)
                    .largeTitleStyle()

                // Avatar and email
                HStack(spacing: Constants.contentPadding) {
                    viewModel.avatarURL.map { url in
                        KFImage(url)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                    }
                    Text(viewModel.email)
                    Spacer()
                }
                .padding(Constants.avatarPadding)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.gray, lineWidth: 1)
                )

                // Password field
                AuthenticationFormFieldView(viewModel: .init(
                    header: Localization.passwordLabel,
                    placeholder: Localization.passwordPlaceholder,
                    keyboardType: .default,
                    text: $viewModel.password,
                    isSecure: true,
                    errorMessage: nil,
                    isFocused: isPasswordFieldFocused
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
                    if isJetpackSetup {
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
        static let avatarSize: CGFloat = 32
        static let avatarPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    enum Localization {
        static let passwordLabel = NSLocalizedString(
            "Enter your WordPress.com password",
            comment: "Label for the password field on the WPCom password login screen of the Jetpack setup flow."
        )
        static let passwordPlaceholder = NSLocalizedString(
            "Enter password",
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
            "Or Continue using Magic Link",
            comment: "Button to switch to magic link on the WPCom password login screen of the Jetpack setup flow."
        )
    }
}

struct WPComPasswordLoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPComPasswordLoginView(title: "Install Jetpack",
                               isJetpackSetup: true,
                               viewModel: .init(siteURL: "https://example.com",
                                                email: "test@example.com",
                                                onMagicLinkRequest: { _ in },
                                                onMultifactorCodeRequest: { _ in },
                                                onLoginFailure: { _ in },
                                                onLoginSuccess: { _ in }))
    }
}
