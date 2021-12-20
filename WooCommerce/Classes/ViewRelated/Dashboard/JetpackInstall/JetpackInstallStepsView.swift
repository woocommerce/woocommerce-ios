import SwiftUI

struct JetpackInstallStepsView: View {
    // Closure invoked when Contact Support button is tapped
    private let supportAction: () -> Void

    // Closure invoked when Done button is tapped
    private let dismissAction: () -> Void

    /// The site for which Jetpack should be installed
    private let siteURL: String

    /// WPAdmin URL to navigate user when install fails.
    private var wpAdminURL: URL? {
        switch viewModel.currentStep {
        case .installation:
            return URL(string: "\(siteURL)\(Constants.wpAdminInstallPath)")
        case .activation:
            return URL(string: "\(siteURL)\(Constants.wpAdminPluginsPath)")
        default:
            return nil
        }
    }

    /// Whether the WPAdmin webview is being shown.
    @State private var showingWPAdminWebview: Bool = false

    // View model to handle the installation
    @ObservedObject private var viewModel: JetpackInstallStepsViewModel

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

    init(siteURL: String,
         viewModel: JetpackInstallStepsViewModel,
         supportAction: @escaping () -> Void,
         dismissAction: @escaping () -> Void) {
        self.siteURL = siteURL
        self.viewModel = viewModel
        self.supportAction = supportAction
        self.dismissAction = dismissAction
        viewModel.startInstallation()
    }

    var body: some View {
        VStack {
            HStack {
                Button(Localization.closeButton, action: dismissAction)
                .buttonStyle(LinkButtonStyle())
                .fixedSize(horizontal: true, vertical: false)
                .padding(.top, Constants.cancelButtonTopMargin)
                Spacer()
            }
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
                    Text(viewModel.installFailed ? Localization.errorTitle :  Localization.installTitle)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color(.text))
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.installFailed {
                        Text(viewModel.currentStep == .connection ? Localization.connectionErrorMessage :  Localization.installErrorMessage)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        AttributedText(descriptionAttributedString)
                    }
                }

                // Loading indicator for when checking plugin details
                HStack {
                    Spacer()
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    Spacer()
                }
                .renderedIf(viewModel.currentStep == nil)

                // Install steps
                VStack(alignment: .leading, spacing: Constants.stepItemsVerticalSpacing) {
                    viewModel.currentStep.map { currentStep in
                        ForEach(JetpackInstallStep.allCases) { step in
                            HStack(spacing: Constants.stepItemHorizontalSpacing) {
                                if step == currentStep, step != .done {
                                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                                } else if step > currentStep {
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
                                    .if(step <= currentStep) {
                                        $0.bold()
                                    }
                                    .foregroundColor(Color(.text))
                                    .opacity(step <= currentStep ? 1 : 0.5)
                            }
                        }
                    }
                }
                .renderedIf(!viewModel.installFailed)
            }
            .padding(.horizontal, Constants.contentHorizontalMargin)
            .scrollVerticallyIfNeeded()

            Spacer()

            // Done Button to dismiss Install Jetpack
            Button(Localization.doneButton, action: dismissAction)
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .padding(Constants.actionButtonMargin)
                .renderedIf(viewModel.currentStep == .done)

            // Error state action buttons
            if viewModel.installFailed {
                VStack(spacing: Constants.actionButtonMargin) {
                    if viewModel.currentStep == .connection {
                        Button(Localization.checkConnectionAction) {
                            viewModel.checkSiteConnection()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Button(Localization.wpAdminAction) {
                            showingWPAdminWebview = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(Localization.supportAction, action: supportAction)
                    .buttonStyle(SecondaryButtonStyle())
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Constants.actionButtonMargin)
            }
        }
        .if(wpAdminURL != nil) { view in
            view.safariSheet(isPresented: $showingWPAdminWebview, url: wpAdminURL, onDismiss: {
                showingWPAdminWebview = false
                viewModel.checkJetpackPluginDetails()
            })
        }
    }
}

private extension JetpackInstallStepsView {
    enum Constants {
        static let cancelButtonTopMargin: CGFloat = 8
        static let headerContentSpacing: CGFloat = 8
        static let contentTopMargin: CGFloat = 32
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
        // TODO-5365: Remove the hard-code wp-admin by fetching option admin_url for sites
        static let wpAdminInstallPath: String = "/wp-admin/plugin-install.php?tab=plugin-information&plugin=jetpack"
        static let wpAdminPluginsPath: String = "/wp-admin/plugins.php"
    }

    enum Localization {
        static let closeButton = NSLocalizedString("Close", comment: "Title of the Close action on the Jetpack Install view")
        static let installTitle = NSLocalizedString("Install Jetpack", comment: "Title of the Install Jetpack view")
        static let installDescription = NSLocalizedString("Please wait while we connect your site %1$@ with Jetpack.",
                                                          comment: "Message on the Jetpack Install Progress screen. The %1$@ is the site address.")
        static let doneButton = NSLocalizedString("Done", comment: "Done button on the Jetpack Install Progress screen.")
        static let errorTitle = NSLocalizedString("Sorry, something went wrong during install", comment: "Error title when Jetpack install fails")
        static let installErrorMessage = NSLocalizedString("Please try again. Alternatively, you can install Jetpack through your WP-Admin.",
                                                    comment: "Error message when Jetpack install fails")
        static let connectionErrorMessage = NSLocalizedString("Please try again or contact us for support.",
                                                              comment: "Error message when Jetpack connection fails")
        static let wpAdminAction = NSLocalizedString("Install Jetpack in WP-Admin", comment: "Action button to install Jetpack win WP-Admin instead of on app")
        static let supportAction = NSLocalizedString("Contact Support", comment: "Action button to contact support when Jetpack install fails")
        static let checkConnectionAction = NSLocalizedString("Retry Connection", comment: "Action button to check site's connection again.")
    }
}

struct JetpackInstallStepsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = JetpackInstallStepsViewModel(siteID: 123)
        JetpackInstallStepsView(siteURL: "automattic.com", viewModel: viewModel, supportAction: {}, dismissAction: {})
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))

        JetpackInstallStepsView(siteURL: "automattic.com", viewModel: viewModel, supportAction: {}, dismissAction: {})
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 414, height: 780))
    }
}
