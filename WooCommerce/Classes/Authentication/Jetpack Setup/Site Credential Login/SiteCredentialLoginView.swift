import SwiftUI

/// Hosting controller that wraps the `SiteCredentialLoginView`.
final class SiteCredentialLoginHostingViewController: UIHostingController<SiteCredentialLoginView> {
    init(siteURL: String, connectionOnly: Bool, onLoginSuccess: @escaping (String) -> Void) {
        let viewModel = SiteCredentialLoginViewModel(siteURL: siteURL, onLoginSuccess: onLoginSuccess)
        super.init(rootView: SiteCredentialLoginView(connectionOnly: connectionOnly, viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
        dismiss(animated: true)
    }
}

/// The view for inputing site credentials.
///
struct SiteCredentialLoginView: View {

    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private let connectionOnly: Bool

    @ObservedObject private var viewModel: SiteCredentialLoginViewModel

    @FocusState private var keyboardIsShown: Bool

    @State private var showsSecureInput: Bool = true

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    init(connectionOnly: Bool, viewModel: SiteCredentialLoginViewModel) {
        self.connectionOnly = connectionOnly
        self.viewModel = viewModel
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
                    Text(Localization.title)
                        .largeTitleStyle()
                    AttributedText(descriptionAttributedString)
                }

                // text fields
                VStack(alignment: .leading, spacing: Constants.fieldVerticalSpacing) {
                    VStack(alignment: .leading, spacing: Constants.fieldVerticalSpacing) {
                        TextField(Localization.enterUsername, text: $viewModel.username)
                            .textFieldStyle(.plain)
                            .focused($keyboardIsShown)
                            .frame(height: Constants.fieldHeight * scale)
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: Constants.fieldVerticalSpacing) {
                        Group {
                            if showsSecureInput {
                                SecureField(Localization.enterPassword, text: $viewModel.password)
                                    .focused($keyboardIsShown)
                            } else {
                                TextField(Localization.enterPassword, text: $viewModel.password)
                                    .textFieldStyle(.plain)
                                    .focused($keyboardIsShown)
                            }
                        }
                        .frame(height: Constants.fieldHeight * scale)
                        .padding(.trailing, Constants.eyeButtonDimension * scale + Constants.eyeButtonHorizontalPadding)
                        Divider()
                    }
                    .overlay(HStack {
                        Spacer()
                        // Button to show/hide the text field content.
                        Button(action: {
                            showsSecureInput.toggle()
                        }) {
                            Image(systemName: showsSecureInput ? "eye.slash" : "eye")
                                .accentColor(Color(.textSubtle))
                                .frame(width: Constants.eyeButtonDimension * scale,
                                       height: Constants.eyeButtonDimension * scale)
                        }
                        .offset(x: 0, y: -Constants.fieldVerticalSpacing/2)
                    })

                    VStack(alignment: .leading, spacing: Constants.fieldVerticalSpacing) {
                        Button {
                            viewModel.resetPassword()
                        } label: {
                            Text(Localization.resetPassword)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(Color(uiColor: .accent))
                        Divider()
                    }
                }

                Label {
                    Text(Localization.note)
                } icon: {
                    Image(systemName: "info.circle")
                }
                .foregroundColor(Color(uiColor: .secondaryLabel))

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            Button {
                // TODO-8075: add tracks
                keyboardIsShown = false
                viewModel.handleLogin()
            } label: {
                Text(connectionOnly ? Localization.connectJetpack : Localization.installJetpack)
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
        static let title = NSLocalizedString("Log in to your store", comment: "Title of the site credential login screen in the Jetpack setup flow")
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
        static let note = NSLocalizedString(
            "We will ask for your approval to complete the Jetpack connection.",
            comment: "Note at the bottom of the site credential login screen"
        )
        static let ok = NSLocalizedString("OK", comment: "Button to dismiss the error alert on the site credential login screen")
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
