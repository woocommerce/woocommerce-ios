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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
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
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
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
                JetpackInstallHeaderView()

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(viewModel.titleString)
                        .largeTitleStyle()
                    Text(viewModel.subtitleString)
                        .subheadlineStyle()
                }

                // Email field
                AuthenticationFormFieldView(viewModel: .init(
                    header: Localization.emailLabel,
                    placeholder: Localization.enterEmail,
                    keyboardType: .emailAddress,
                    text: $viewModel.emailAddress,
                    isSecure: false,
                    errorMessage: nil,
                    isFocused: isEmailFieldFocused
                ))
                .focused($isEmailFieldFocused)

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(viewModel.titleString) {
                    ServiceLocator.analytics.track(event: .JetpackSetup.loginFlow(step: .emailAddress, tap: .submit))
                    Task { @MainActor in
                        isPrimaryButtonLoading = true
                        await viewModel.checkWordPressComAccount(email: viewModel.emailAddress)
                        isPrimaryButtonLoading = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPrimaryButtonLoading))
                .disabled(viewModel.emailAddress.isEmpty)

                // Terms label
                AttributedText(viewModel.termsAttributedString)
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
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
        static let enterEmail = NSLocalizedString(
            "Enter email or username",
            comment: "Placeholder text for the email field on the WPCom email login screen of the Jetpack setup flow."
        )
    }
}


struct WPComEmailLoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPComEmailLoginView(viewModel: .init(siteURL: "https://example.com",
                                             requiresConnectionOnly: true,
                                             onPasswordUIRequest: { _ in },
                                             onMagicLinkUIRequest: { _ in },
                                             onError: { _ in }))
    }
}
