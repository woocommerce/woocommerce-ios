import SwiftUI

/// Hosting controller for `WPComEmailLoginView`
final class WPComEmailLoginHostingController: UIHostingController<WPComEmailLoginView> {
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    init(siteURL: String, requiresConnectionOnly: Bool, onSubmit: @escaping (String) -> Void) {
        let viewModel = WPComEmailLoginViewModel(siteURL: siteURL, requiresConnectionOnly: requiresConnectionOnly)
        super.init(rootView: WPComEmailLoginView(viewModel: viewModel, onSubmit: onSubmit))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
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

    /// The closure to be triggered when the Install Jetpack button is tapped.
    private let onSubmit: (String) -> Void

    init(viewModel: WPComEmailLoginViewModel,
         onSubmit: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onSubmit = onSubmit
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
                AccountCreationFormFieldView(viewModel: .init(
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
                    onSubmit(viewModel.emailAddress)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isEmailValid)

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
            "Email address",
            comment: "Label for the email field on the WPCom email login screen of the Jetpack setup flow."
        )
        static let enterEmail = NSLocalizedString(
            "Enter email",
            comment: "Placeholder text for the email field on the WPCom email login screen of the Jetpack setup flow."
        )
    }
}


struct WPComEmailLoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPComEmailLoginView(viewModel: .init(siteURL: "https://test.com",
                                             requiresConnectionOnly: true),
                            onSubmit: { _ in })
    }
}
