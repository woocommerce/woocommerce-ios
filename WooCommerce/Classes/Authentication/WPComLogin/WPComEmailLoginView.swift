import SwiftUI
import UIKit

/// Hosting controller for `WPComEmailLoginView`
final class WPComEmailLoginHostingController: UIHostingController<WPComEmailLoginView> {
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    init(viewModel: WPComEmailLoginViewModel) {
        super.init(rootView: WPComEmailLoginView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        navigationController?.presentationController?.delegate = self
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
        }
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
        ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress, tap: .dismiss))
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension WPComEmailLoginHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false // disable swipe to dismiss
    }
}

private extension WPComEmailLoginHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
    }
}


/// Screen for logging in to a WPCom account during the Jetpack setup flow
/// This is presented for users authenticated with WPOrg credentials.
struct WPComEmailLoginView: View {
    @ObservedObject private var viewModel: WPComEmailLoginViewModel
    @FocusState private var isEmailFieldFocused: Bool
    @State private var isPrimaryButtonLoading = false

    init(viewModel: WPComEmailLoginViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                headerView

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(viewModel.titleString)
                        .largeTitleStyle()
                        .bold()
                    Text(viewModel.subtitleString)
                        .bodyStyle()
                }

                // Email field
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    AuthenticationFormFieldView(viewModel: .init(
                        header: viewModel.usernameOnly ? Localization.usernameLabel : Localization.emailLabel,
                        placeholder: viewModel.usernameOnly ? Localization.enterUsername : Localization.enterEmail,
                        keyboardType: viewModel.usernameOnly ? .default : .emailAddress,
                        text: $viewModel.emailOrUsername,
                        isSecure: false,
                        errorMessage: nil,
                        isFocused: isEmailFieldFocused,
                        autocapitalization: .none
                    ))
                    .focused($isEmailFieldFocused)

                    if viewModel.allowAccountCreation,
                       !viewModel.usernameOnly {
                        // Account creation hint
                        Text(Localization.accountCreationHint)
                            .footnoteStyle()
                    }
                }

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(viewModel.primaryButtonTitle) {
                    ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress, tap: .submit))
                    Task { @MainActor in
                        isPrimaryButtonLoading = true
                        await viewModel.checkWordPressComAccount(emailOrUsername: viewModel.emailOrUsername)
                        isPrimaryButtonLoading = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPrimaryButtonLoading))
                .disabled(viewModel.emailOrUsername.isEmpty)

                // Terms label
                Text(viewModel.termsAttributedString)
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPComEmailLoginView {
    @ViewBuilder
    var headerView: some View {
        switch viewModel.flow {
        case .jetpackSetup:
            JetpackInstallHeaderView()
        case .notificationSetup:
            ConnectWPComHeaderView()
        }
    }
}

private extension WPComEmailLoginView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let emailLabel = NSLocalizedString(
            "Email Address or Username",
            comment: "Label for the email field on the WPCom email login screen of the Jetpack setup flow."
        )
        static let usernameLabel = NSLocalizedString(
            "wpComEmailLoginView.usernameLabel",
            value: "Username",
            comment: "Label for the username field on the WPCom email login screen of the Jetpack setup flow."
        )
        static let enterEmail = NSLocalizedString(
            "wpComEmailLoginView.enterEmail",
            value: "Enter email address or username",
            comment: "Placeholder text for the email field on the WPCom email login screen of the Jetpack setup flow."
        )
        static let enterUsername = NSLocalizedString(
            "wpComEmailLoginView.enterUsername",
            value: "Enter username",
            comment: "Placeholder text for the username field on the WPCom email login screen of the Jetpack setup flow."
        )
        static let accountCreationHint = NSLocalizedString(
            "wpComEmailLoginView.accountCreationHint",
            value: "If you don't have an account, we'll use this email to create one.",
            comment: "Text hinting that an account will be created if the email is not associated with an existing account."
        )
    }
}

#Preview("WPComEmailLoginView - notification setup") {
    WPComEmailLoginView(viewModel: .init(siteURL: "https://example.com",
                                         flow: .notificationSetup,
                                         allowAccountCreation: true,
                                         onPasswordUIRequest: { _ in },
                                         onMagicLinkRequest: { _ in },
                                         onMagicLinkSent: { _, _ in },
                                         onError: { _ in }))
}

#Preview("WPComEmailLoginView - Jetpack setup connection only") {
    WPComEmailLoginView(viewModel: .init(siteURL: "https://example.com",
                                         flow: .jetpackSetup(requiresConnectionOnly: true),
                                         allowAccountCreation: true,
                                         onPasswordUIRequest: { _ in },
                                         onMagicLinkRequest: { _ in },
                                         onMagicLinkSent: { _, _ in },
                                         onError: { _ in }))
}

#Preview("WPComEmailLoginView - Jetpack setup") {
    WPComEmailLoginView(viewModel: .init(siteURL: "https://example.com",
                                         flow: .jetpackSetup(requiresConnectionOnly: false),
                                         allowAccountCreation: true,
                                         onPasswordUIRequest: { _ in },
                                         onMagicLinkRequest: { _ in },
                                         onMagicLinkSent: { _, _ in },
                                         onError: { _ in }))
}
