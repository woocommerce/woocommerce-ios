import SwiftUI

struct JetpackInstallStepsView: View {
    // Closure invoked when Done button is tapped
    private let dismissAction: () -> Void

    /// The site for which Jetpack should be installed
    private let siteURL: String

    // View model to handle the installation
    private let viewModel: JetpackInstallStepsViewModel

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    /// Attributed string for the description text
    private var descriptionAttributedString: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold
        let siteName = siteURL.trimHTTPScheme()

        let attributedString = NSMutableAttributedString(
            string: String(format: Localization.installDescription, siteName),
            attributes: [.font: font,
                         .foregroundColor: UIColor.text.withAlphaComponent(0.8)
                        ]
        )
        let boldSiteAddress = NSAttributedString(string: siteName, attributes: [.font: boldFont, .foregroundColor: UIColor.text])
        attributedString.replaceFirstOccurrence(of: siteName, with: boldSiteAddress)
        return attributedString
    }

    init(siteURL: String, viewModel: JetpackInstallStepsViewModel, dismissAction: @escaping () -> Void) {
        self.siteURL = siteURL
        self.viewModel = viewModel
        self.dismissAction = dismissAction
    }

    var body: some View {
        VStack {
            // Main content
            VStack(alignment: .leading, spacing: Constants.contentSpacing) {
                // Header
                HStack(spacing: Constants.headerContentSpacing) {
                    Image(uiImage: .jetpackGreenLogoImage)
                        .resizable()
                        .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
                    Image(uiImage: .connectionImage)
                        .resizable()
                        .flipsForRightToLeftLayoutDirection(true)
                        .frame(width: Constants.connectionIconSize * scale, height: Constants.connectionIconSize * scale)

                    if let image = UIImage.wooLogoImage(tintColor: .white) {
                        Circle()
                            .foregroundColor(Color(.withColorStudio(.wooCommercePurple, shade: .shade60)))
                            .frame(width: Constants.logoSize * scale, height: Constants.logoSize * scale)
                            .overlay(
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: Constants.wooIconSize.width * scale, height: Constants.wooIconSize.height * scale)
                            )
                    }

                    Spacer()
                }
                .padding(.top, Constants.contentTopMargin)

                // Title and description
                VStack(alignment: .leading, spacing: Constants.textSpacing) {
                    Text(Localization.installTitle)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color(.text))

                    AttributedText(descriptionAttributedString)
                }

                // Install steps
                VStack(alignment: .leading, spacing: Constants.stepItemsVerticalSpacing) {
                    ForEach(JetpackInstallStep.allCases) { step in
                        HStack(spacing: Constants.stepItemHorizontalSpacing) {
                            if step == viewModel.currentStep, step != .done {
                                ActivityIndicator(isAnimating: .constant(true), style: .medium)
                            } else if step > viewModel.currentStep {
                                Image(uiImage: .checkEmptyCircleImage)
                                    .resizable()
                                    .frame(width: Constants.stepImageSize * scale, height: Constants.stepImageSize * scale)
                            } else {
                                Image(uiImage: .checkCircleImage)
                                    .resizable()
                                    .frame(width: Constants.stepImageSize * scale, height: Constants.stepImageSize * scale)
                            }

                            Text(step.title)
                                .font(.body)
                                .if(step <= viewModel.currentStep) {
                                    $0.bold()
                                }
                                .foregroundColor(Color(.text))
                                .opacity(step <= viewModel.currentStep ? 1 : 0.5)
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.contentHorizontalMargin)
            .scrollVerticallyIfNeeded()

            Spacer()

            // Done Button to dismiss Install Jetpack
            Button(Localization.doneButton, action: dismissAction)
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .padding(Constants.actionButtonMargin)
        }
    }
}

private extension JetpackInstallStepsView {
    enum Constants {
        static let headerContentSpacing: CGFloat = 8
        static let contentTopMargin: CGFloat = 80
        static let contentHorizontalMargin: CGFloat = 40
        static let contentSpacing: CGFloat = 32
        static let logoSize: CGFloat = 40
        static let wooIconSize: CGSize = .init(width: 30, height: 18)
        static let connectionIconSize: CGFloat = 10
        static let textSpacing: CGFloat = 12
        static let actionButtonMargin: CGFloat = 16
        static let stepItemHorizontalSpacing: CGFloat = 24
        static let stepItemsVerticalSpacing: CGFloat = 20
        static let stepImageSize: CGFloat = 24
    }

    enum Localization {
        static let installTitle = NSLocalizedString("Install Jetpack", comment: "Title of the Install Jetpack view")
        static let installDescription = NSLocalizedString("Please wait while we connect your site %1$@ with Jetpack.",
                                                          comment: "Message on the Jetpack Install Progress screen. The %1$@ is the site address.")
        static let doneButton = NSLocalizedString("Done", comment: "Done button on the Jetpack Install Progress screen.")
    }
}

struct JetpackInstallStepsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = JetpackInstallStepsViewModel(siteID: 123)
        JetpackInstallStepsView(siteURL: "automattic.com", viewModel: viewModel, dismissAction: {})
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))

        JetpackInstallStepsView(siteURL: "automattic.com", viewModel: viewModel, dismissAction: {})
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 414, height: 780))
    }
}
