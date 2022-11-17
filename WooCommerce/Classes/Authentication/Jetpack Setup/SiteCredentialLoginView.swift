import SwiftUI

/// Hosting controller that wraps the `SiteCredentialLoginView`.
final class SiteCredentialLoginHostingViewController: UIHostingController<SiteCredentialLoginView> {
    init(siteURL: String, connectionOnly: Bool) {
        super.init(rootView: SiteCredentialLoginView(siteURL: siteURL, connectionOnly: connectionOnly))
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
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
}

/// The view for inputing site credentials.
///
struct SiteCredentialLoginView: View {

    let siteURL: String
    let connectionOnly: Bool

    /// Attributed string for the description text
    private var descriptionAttributedString: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = siteURL.trimHTTPScheme()
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
            VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                JetpackInstallHeaderView()
                    .padding(.vertical, Constants.headerVerticalPadding)
                Text(Localization.title)
                    .largeTitleStyle()
                AttributedText(descriptionAttributedString)
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            Button {
                // TODO
            } label: {
                Text(connectionOnly ? Localization.connectJetpack : Localization.installJetpack)
            }
            .buttonStyle(PrimaryButtonStyle())

        })
        .padding()
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
    }

    enum Constants {
        static let headerVerticalPadding: CGFloat = 24
        static let contentVerticalSpacing: CGFloat = 8
    }
}

struct SiteCredentialLoginView_Previews: PreviewProvider {
    static var previews: some View {
        SiteCredentialLoginView(siteURL: "https://test.com", connectionOnly: true)
        SiteCredentialLoginView(siteURL: "https://test.com", connectionOnly: false)
    }
}
