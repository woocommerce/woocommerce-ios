import SwiftUI
import class WordPressAuthenticator.LoginFields

/// Hosting controller for `WPCom2FALoginView`
final class WPCom2FALoginHostingController: UIHostingController<WPCom2FALoginView> {

    private let flow: WPComLoginFlow

    /// Inits the hosting controller for `WPCom2FALoginView`.
    /// Params:
    ///   - title: Title to display at the top of the 2FA view.
    ///   - isJetpackSetup: Whether the view is part of the login step of the Jetpack setup flow.
    ///   - viewModel: The model for the view.
    ///
    init(title: String, flow: WPComLoginFlow, viewModel: WPCom2FALoginViewModel) {
        self.flow = flow
        super.init(rootView: WPCom2FALoginView(title: title, flow: flow, viewModel: viewModel))
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
        if isMovingFromParent, case .jetpackSetup = flow {
            ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, tap: .dismiss))
        }
    }
}

/// View for 2FA login screen of the custom WPCom login flow for Jetpack setup.
struct WPCom2FALoginView: View {
    @ObservedObject private var viewModel: WPCom2FALoginViewModel
    @FocusState private var isFieldFocused: Bool

    /// Title to display at the top of the 2FA view.
    private let title: String

    private let flow: WPComLoginFlow

    init(title: String, flow: WPComLoginFlow, viewModel: WPCom2FALoginViewModel) {
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
                case .notificationSetup:
                    ConnectWPComHeaderView()
                }

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(title)
                        .largeTitleStyle()
                        .bold()
                    Text(Localization.subtitleString)
                        .bodyStyle()
                }

                // Verification field
                AuthenticationFormFieldView(viewModel: .init(
                    header: nil,
                    placeholder: Localization.verificationCode,
                    keyboardType: .asciiCapableNumberPad,
                    text: $viewModel.verificationCode,
                    isSecure: false,
                    errorMessage: nil,
                    isFocused: isFieldFocused,
                    autocapitalization: .none
                ))
                .focused($isFieldFocused)

                Text(Localization.anotherFormText)
                    .bodyStyle()

                // Text me a code button
                Button(action: {
                    viewModel.requestOneTimeCode()
                }, label: {
                    if viewModel.isRequestingOTP {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Label(Localization.textMeACode, systemImage: "platter.filled.top.iphone")
                            .linkStyle()
                    }
                })

                if #available(iOS 16, *), viewModel.shouldEnableSecurityKeyOption {
                    // Security key button
                    Button {
                        viewModel.loginWithSecurityKey()
                    } label: {
                        Label(Localization.securityKey, systemImage: "key.horizontal")
                            .linkStyle()
                    }
                }

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(title) {
                    if case .jetpackSetup = flow {
                        ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .verificationCode, tap: .submit))
                    }
                    viewModel.handleLogin()
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoggingIn))
                .disabled(!viewModel.isValidCode)
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPCom2FALoginView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 24
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let subtitleString = NSLocalizedString(
            "wpCom2FALoginView.subtitleString",
            value: "Almost there! Please enter the verification code from your Authentication app",
            comment: "Instruction on the WPCom 2FA login screen")
        static let verificationCode = NSLocalizedString(
            "wpCom2FALoginView.verificationCode",
            value: "Verification code",
            comment: "Placeholder for the 2FA code field on the WPCom 2FA login screen"
        )
        static let textMeACode = NSLocalizedString(
            "wpCom2FALoginView.textMeACode",
            value: "Text me a code instead",
            comment: "Button to request 2FA code via SMS on the WPCom 2FA login screen"
        )
        static let securityKey = NSLocalizedString(
            "wpCom2FALoginView.securityKeyButton",
            value: "Use a security key",
            comment: "Button to enter security key on the WPCom 2FA login screen"
        )
        static let anotherFormText = NSLocalizedString(
            "wpCom2FALoginView.anotherFormText",
            value: "Or choose another form of authentication.",
            comment: "This text appears on the WordPress.com two-factor authentication login screen as explanatory text that introduces alternative authentication options like SMS codes or security keys to users."
        )
    }
}

struct WPCom2FALoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPCom2FALoginView(title: "Connect to WordPress.com ",
                          flow: .notificationSetup,
                          viewModel: .init(loginFields: LoginFields(),
                                           onAuthWindowRequest: { UIViewController().view.window! },
                                           onLoginFailure: { _ in },
                                           onLoginSuccess: { _ in }))
    }
}
