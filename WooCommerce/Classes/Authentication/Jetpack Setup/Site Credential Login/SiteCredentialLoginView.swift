import SwiftUI

/// Hosting controller that wraps the `SiteCredentialLoginView`.
final class SiteCredentialLoginHostingViewController: UIHostingController<SiteCredentialLoginView> {
    private let analytics: Analytics

    init(siteURL: String,
         connectionOnly: Bool,
         analytics: Analytics = ServiceLocator.analytics,
         onLoginSuccess: @escaping () -> Void) {
        self.analytics = analytics
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, onLoginSuccess: onLoginSuccess)
        super.init(rootView: SiteCredentialLoginView(connectionOnly: connectionOnly, viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        analytics.track(.loginJetpackSiteCredentialScreenViewed)
        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border.
    private func configureNavigationBarAppearance() {
        configureTransparentNavigationBar()

        let title = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        analytics.track(.loginJetpackSiteCredentialScreenDismissed)
        dismiss(animated: true)
    }
}

/// The view for inputing site credentials.
///
struct SiteCredentialLoginView: View {
    private enum Field: Hashable {
        case username
        case password
    }

    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private let connectionOnly: Bool
    private let title: String

    @ObservedObject private var viewModel: SiteCredentialLoginViewModel

    @FocusState private var focusedField: Field?

    @State private var showsSecureInput: Bool = true

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    init(connectionOnly: Bool, viewModel: SiteCredentialLoginViewModel) {
        self.connectionOnly = connectionOnly
        self.viewModel = viewModel
        self.title = connectionOnly ? Localization.connectJetpack : Localization.installJetpack
    }

    /// Attributed string for the description text
    private var descriptionAttributedString: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = viewModel.siteURL.trimHTTPScheme()
        let description = connectionOnly ? Localization.connectDescription : Localization.installDescription

        let attributedString = NSMutableAttributedString(
            string: String(format: description, siteName),
            attributes: [.font: font,
                         .foregroundColor: UIColor.text.withAlphaComponent(0.8)
                        ]
        )
        let boldSiteAddress = NSAttributedString(string: siteName, attributes: [.font: boldFont, .foregroundColor: UIColor.text])
        attributedString.replaceFirstOccurrence(of: siteName, with: boldSiteAddress)
        return attributedString
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(title)
                        .largeTitleStyle()
                    AttributedText(descriptionAttributedString)
                }

                // text fields
                VStack(alignment: .leading, spacing: Constants.fieldVerticalSpacing) {
                    // Username field.
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.usernameFieldTitle,
                                                                  placeholder: Localization.enterUsername,
                                                                  keyboardType: .default,
                                                                  text: $viewModel.username,
                                                                  isSecure: false,
                                                                  errorMessage: nil,
                                                                  isFocused: focusedField == .username))
                    .focused($focusedField, equals: .username)
                    .disabled(viewModel.isLoggingIn)

                    // Password field.
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.passwordFieldTitle,
                                                                  placeholder: Localization.enterPassword,
                                                                  keyboardType: .default,
                                                                  text: $viewModel.password,
                                                                  isSecure: true,
                                                                  errorMessage: nil,
                                                                  isFocused: focusedField == .password))
                    .focused($focusedField, equals: .password)
                    .disabled(viewModel.isLoggingIn)

                    // Reset password button
                    Button {
                        viewModel.resetPassword()
                    } label: {
                        Text(Localization.resetPassword)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(Color(uiColor: .accent))
                }

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            Button {
                focusedField = nil
                viewModel.handleLogin()
            } label: {
                Text(title)
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoggingIn))
            .disabled(viewModel.primaryButtonDisabled)
            .padding(.top, Constants.contentVerticalSpacing)
            .background(Color(UIColor.systemBackground))
        })
        .padding()
        .alert(viewModel.errorMessage, isPresented: $viewModel.shouldShowErrorAlert) {
            Button(Localization.ok) {
                viewModel.shouldShowErrorAlert.toggle()
            }
        }
    }
}

private extension SiteCredentialLoginView {
    enum Localization {
        static let installDescription = NSLocalizedString(
            "Log in to %1$@ with your store credentials to install Jetpack.",
            comment: "Message on the site credential login screen for installing Jetpack. The %1$@ is the site address."
        )
        static let connectDescription = NSLocalizedString(
            "Log in to %1$@ with your store credentials to connect Jetpack.",
            comment: "Message on the site credential login screen for connecting Jetpack. The %1$@ is the site address."
        )
        static let installJetpack = NSLocalizedString("Install Jetpack", comment: "Button title on the site credential login screen")
        static let connectJetpack = NSLocalizedString("Connect Jetpack", comment: "Button title on the site credential login screen")
        static let enterUsername = NSLocalizedString("Enter username", comment: "Placeholder for the username field on the site credential login screen")
        static let enterPassword = NSLocalizedString("Enter password", comment: "Placeholder for the password field on the site credential login screen")
        static let resetPassword = NSLocalizedString("Reset your password", comment: "Button to reset password on the site credential login screen")
        static let ok = NSLocalizedString("OK", comment: "Button to dismiss the error alert on the site credential login screen")
        static let usernameFieldTitle = NSLocalizedString("Username", comment: "Title of the email field on the site credential login screen")
        static let passwordFieldTitle = NSLocalizedString("Password", comment: "Title of the password field on the site credential login screen")
    }

    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let fieldVerticalSpacing: CGFloat = 16
        static let eyeButtonHorizontalPadding: CGFloat = 8
        static let eyeButtonDimension: CGFloat = 24
        static let fieldHeight: CGFloat = 24
    }
}

struct SiteCredentialLoginView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SiteCredentialLoginViewModel(siteURL: "https://test.com")
        SiteCredentialLoginView(connectionOnly: true, viewModel: viewModel)
        SiteCredentialLoginView(connectionOnly: false, viewModel: viewModel)
    }
}
