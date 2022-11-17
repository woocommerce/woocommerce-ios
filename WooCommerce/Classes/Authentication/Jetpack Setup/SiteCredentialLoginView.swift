import SwiftUI

/// Hosting controller that wraps the `SiteCredentialLoginView`.
final class SiteCredentialLoginHostingViewController: UIHostingController<SiteCredentialLoginView> {
    init(siteURL: String) {
        super.init(rootView: SiteCredentialLoginView(siteURL: siteURL))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The view for inputing site credentials.
///
struct SiteCredentialLoginView: View {

    let siteURL: String

    /// Attributed string for the description text
    private var descriptionAttributedString: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = siteURL.trimHTTPScheme()

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
        VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
            JetpackInstallHeaderView()
                .padding(.vertical, Constants.headerVerticalPadding)
            Text(Localization.title)
                .largeTitleStyle()
            AttributedText(descriptionAttributedString)
            Spacer()
        }
        .scrollVerticallyIfNeeded()
    }
}

private extension SiteCredentialLoginView {
    enum Localization {
        static let title = NSLocalizedString("Log in to your store", comment: "Title of the site credential login screen in the Jetpack setup flow")
        static let description = NSLocalizedString(
            "Log in to %1$@ with your store credentials to install Jetpack.",
            comment: "Message on the site credential login screen. The %1$@ is the site address."
        )
    }

    enum Constants {
        static let headerVerticalPadding: CGFloat = 24
        static let contentVerticalSpacing: CGFloat = 8
    }
}

struct SiteCredentialLoginView_Previews: PreviewProvider {
    static var previews: some View {
        SiteCredentialLoginView(siteURL: "https://test.com")
    }
}
