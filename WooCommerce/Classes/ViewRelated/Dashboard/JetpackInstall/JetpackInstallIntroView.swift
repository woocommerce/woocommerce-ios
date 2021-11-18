import SwiftUI

struct JetpackInstallIntroView: View {
    // Closure invoked when Close button is tapped
    var dismissAction: () -> Void = {}

    let siteURL: String

    private var descriptionAttributedString: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = siteURL.trimHTTPScheme()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributedString = NSMutableAttributedString(
            string: String(format: Localization.installDescription, siteName),
            attributes: [.font: font,
                         .foregroundColor: UIColor.primary,
                         .paragraphStyle: paragraphStyle
                        ]
        )
        let boldSiteAddress = NSAttributedString(string: siteName, attributes: [.font: boldFont])
        attributedString.replaceFirstOccurrence(of: siteName, with: boldSiteAddress)
        return attributedString
    }

    var body: some View {
        VStack {
            HStack {
                Button(Localization.closeButton, action: dismissAction)
                .buttonStyle(LinkButtonStyle())
                .fixedSize(horizontal: true, vertical: true)
                Spacer()
            }

            Spacer()

            VStack(spacing: Constants.contentSpacing) {
                Image(uiImage: .jetpackLogoImage)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(.jetpackGreen))
                    .frame(width: Constants.jetpackLogoSize, height: Constants.jetpackLogoSize)

                Text(Localization.installTitle)
                    .font(.largeTitle)
                    .foregroundColor(.primary)

                AttributedText(descriptionAttributedString)
            }
            .padding(.horizontal, Constants.contentHorizontalMargin)
            .scrollVerticallyIfNeeded()

            Spacer()

            // Primary Button to install Jetpack
            Button(Localization.installAction, action: {
                // TODO: Show main install screen
            })
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Constants.actionButtonHorizontalMargin)
                .padding(.bottom, Constants.actionButtonBottomMargin)
        }
    }
}

private extension JetpackInstallIntroView {
    enum Constants {
        static let jetpackLogoSize: CGFloat = 120
        static let actionButtonHorizontalMargin: CGFloat = 16
        static let actionButtonBottomMargin: CGFloat = 28
        static let contentHorizontalMargin: CGFloat = 40
        static let contentSpacing: CGFloat = 8
        static let jetpackLogoBottomMargin: CGFloat = 24
    }

    enum Localization {
        static let closeButton = NSLocalizedString("Close", comment: "Title of the Close action on the Jetpack Install view")
        static let installAction = NSLocalizedString("Get Started", comment: "Title of install action in the Jetpack benefits view.")
        static let installTitle = NSLocalizedString("Install Jetpack", comment: "Title of the Install Jetpack intro view")
        static let installDescription = NSLocalizedString("Install the free Jetpack plugin to %1$@ and experience the best mobile experience.",
                                                          comment: "Description of the Jetpack Install flow for the specified site")
    }
}

struct JetpackInstallIntroView_Previews: PreviewProvider {
    static var previews: some View {
        JetpackInstallIntroView(siteURL: "automattic.com")
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))

        JetpackInstallIntroView(siteURL: "automattic.com")
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 800, height: 300))
    }
}
