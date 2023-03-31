import SwiftUI
import class WordPressAuthenticator.LoginFields

/// Hosting controller for `WPCom2FALoginView`
final class WPCom2FALoginHostingController: UIHostingController<WPCom2FALoginView> {

    init(viewModel: WPCom2FALoginViewModel) {
        super.init(rootView: WPCom2FALoginView(viewModel: viewModel))
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
        if isMovingFromParent {
            ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .magicLink, tap: .dismiss))
        }
    }
}

/// View for 2FA login screen of the custom WPCom login flow for Jetpack setup.
struct WPCom2FALoginView: View {
    @ObservedObject private var viewModel: WPCom2FALoginViewModel
    @FocusState private var isFieldFocused: Bool

    init(viewModel: WPCom2FALoginViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(viewModel.titleString)
                        .largeTitleStyle()
                    Text(Localization.subtitleString)
                        .subheadlineStyle()
                }

                // Verification field
                AuthenticationFormFieldView(viewModel: .init(
                    header: nil,
                    placeholder: Localization.verificationCode,
                    keyboardType: .asciiCapableNumberPad,
                    text: $viewModel.verificationCode,
                    isSecure: false,
                    errorMessage: nil,
                    isFocused: isFieldFocused
                ))
                .focused($isFieldFocused)

                // Text me a code button
                Button(action: {
                    viewModel.requestOneTimeCode()
                }, label: {
                    if viewModel.isRequestingOTP {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Text(Localization.textMeACode)
                            .linkStyle()
                    }
                })
                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(viewModel.titleString) {
                    ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .verificationCode, tap: .submit))
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
            "Almost there! Please enter the verification code from your Authentication app",
            comment: "Instruction on the WPCom 2FA login screen of the Jetpack setup flow")
        static let verificationCode = NSLocalizedString(
            "Verification code",
            comment: "Placeholder for the 2FA code field on the WPCom 2FA login screen of the Jetpack setup flow."
        )
        static let textMeACode = NSLocalizedString(
            "Text me a code instead",
            comment: "Button to request 2FA code via SMS on the WPCom 2FA login screen of the Jetpack setup flow."
        )
    }
}

struct WPCom2FALoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPCom2FALoginView(viewModel: .init(loginFields: LoginFields(),
                                           requiresConnectionOnly: true,
                                           onLoginFailure: { _ in },
                                           onLoginSuccess: { _ in }))
    }
}
