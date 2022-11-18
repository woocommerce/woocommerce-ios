import SwiftUI

/// Hosting controller for `LoginJetpackSetupView`.
///
final class LoginJetpackSetupHostingController: UIHostingController<LoginJetpackSetupView> {
    init(siteURL: String, connectionOnly: Bool) {
        let viewModel = LoginJetpackSetupViewModel(siteURL: siteURL, connectionOnly: connectionOnly)
        super.init(rootView: LoginJetpackSetupView(viewModel: viewModel))
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
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

        let title = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

/// View to show the process of Jetpack setup during login.
///
struct LoginJetpackSetupView: View {
    @ObservedObject private var viewModel: LoginJetpackSetupViewModel

    init(viewModel: LoginJetpackSetupViewModel) {
        self.viewModel = viewModel
    }

    private var title: String {
        viewModel.connectionOnly ? Localization.connectingJetpack : Localization.installingJetpack
    }

    /// Attributed string for the description text
    private var descriptionAttributedString: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = viewModel.siteURL.trimHTTPScheme()

        let attributedString = NSMutableAttributedString(
            string: String(format: Localization.description, siteName),
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

                Spacer()
            }
        }
        .padding()
    }
}

private extension LoginJetpackSetupView {
    enum Localization {
        static let installingJetpack = NSLocalizedString(
            "Installing Jetpack",
            comment: "Title for the Jetpack setup screen when installation is required"
        )
        static let connectingJetpack = NSLocalizedString(
            "Installing Jetpack",
            comment: "Title for the Jetpack setup screen when connection is required"
        )
        static let description = NSLocalizedString(
            "Please wait while we connect your store %1$@ with Jetpack.",
            comment: "Message on the Jetpack setup screen. The %1$@ is the site address."
        )
    }

    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
    }
}

struct LoginJetpackSetupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: true))
        LoginJetpackSetupView(viewModel: LoginJetpackSetupViewModel(siteURL: "https://test.com", connectionOnly: false))
    }
}
