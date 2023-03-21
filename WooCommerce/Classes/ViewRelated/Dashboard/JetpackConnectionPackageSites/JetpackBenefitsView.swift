import SwiftUI
import Yosemite

/// Hosting controller wrapper for `JetpackBenefitsView`
///
final class JetpackBenefitsHostingController: UIHostingController<JetpackBenefitsView> {
    init(siteURL: String, isJetpackCPSite: Bool) {
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: isJetpackCPSite)
        super.init(rootView: JetpackBenefitsView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setActions(installAction: @escaping (Result<JetpackUser, Error>) -> Void,
                    dismissAction: @escaping () -> Void) {
        rootView.installAction = installAction
        rootView.dismissAction = dismissAction
    }
}

/// Displays a list of Jetpack benefits with two CTAs to install Jetpack and dismiss the view.
struct JetpackBenefitsView: View {

    private let viewModel: JetpackBenefitsViewModel

    /// Closure invoked when the install button is tapped
    ///
    var installAction: (Result<JetpackUser, Error>) -> Void = { _ in }

    /// Closure invoked when the "Not Now" button is tapped
    ///
    var dismissAction: () -> Void = {}

    init(viewModel: JetpackBenefitsViewModel) {
        self.viewModel = viewModel
    }

    @State private var isPrimaryButtonLoading = false
    @State private var isShowingWPAdmin = false

    var body: some View {
        VStack {
            VStack {
                Spacer().frame(height: Layout.topPadding)

                // Title & subtitle
                VStack(spacing: Layout.spacingBetweenTitleAndSubtitle) {
                    LargeTitle(text: Localization.title).largeTitleStyle()
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                    Text(Localization.subtitle).bodyStyle()
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: Layout.verticalSpacing)

                // Benefit list
                VStack {
                    JetpackBenefitItem(title: Localization.pushNotificationsBenefitTitle,
                                       subtitle: Localization.pushNotificationsBenefitSubtitle,
                                       icon: .alarmBellRingImage)
                    JetpackBenefitItem(title: Localization.analyticsBenefitTitle,
                                       subtitle: Localization.analyticsBenefitSubtitle,
                                       icon: .analyticsImage)
                    if viewModel.isJetpackCPSite {
                        JetpackBenefitItem(title: Localization.userProfilesBenefitTitle,
                                           subtitle: Localization.userProfilesBenefitSubtitle,
                                           icon: .multipleUsersImage)
                    } else {
                        JetpackBenefitItem(title: Localization.multiStoresBenefitTitle,
                                           subtitle: Localization.multiStoresBenefitSubtitle,
                                           icon: .multipleStoresImage)
                    }
                }.padding([.leading, .trailing], insets: Layout.horizontalPaddingInBenefitList)

                Spacer().frame(height: Layout.verticalSpacing)
            }.scrollVerticallyIfNeeded()

            Spacer()

            // Actions
            VStack(spacing: Layout.spacingBetweenCTAs) {
                // Primary Button to install Jetpack
                Button(viewModel.isJetpackCPSite ? Localization.installAction : Localization.loginAction) {
                    Task { @MainActor in
                        isPrimaryButtonLoading = true
                        let result = await viewModel.fetchJetpackUser()
                        isPrimaryButtonLoading = false
                        installAction(result)
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPrimaryButtonLoading))
                .fixedSize(horizontal: false, vertical: true)
                .renderedIf(viewModel.shouldShowWebViewForJetpackInstall == false)

                // Button to open wp-admin to install Jetpack
                Button(Localization.wpAdminAction) {
                    isShowingWPAdmin = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .fixedSize(horizontal: false, vertical: true)
                .renderedIf(viewModel.shouldShowWebViewForJetpackInstall)

                // Secondary button to dismiss
                Button(viewModel.shouldShowWebViewForJetpackInstall ? Localization.dismissAction : Localization.notNowAction, action: dismissAction)
                    .buttonStyle(SecondaryButtonStyle())
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(insets: Layout.contentPadding)
        .safariSheet(isPresented: $isShowingWPAdmin, url: viewModel.wpAdminInstallURL)
    }
}

private extension JetpackBenefitsView {

    enum Layout {
        static let topPadding = CGFloat(75)
        static let spacingBetweenTitleAndSubtitle = CGFloat(10)
        static let spacingBetweenCTAs = CGFloat(16)
        static let verticalSpacing = CGFloat(32)
        static let horizontalPaddingInBenefitList = EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
        static let contentPadding = EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
    }

    enum Localization {
        static let title = NSLocalizedString("Get the most out of your store", comment: "Title of the Jetpack benefits view.")
        static let subtitle = NSLocalizedString("Install the free Jetpack plugin to experience the best mobile experience.",
                                                comment: "Subtitle of the Jetpack benefits view.")
        static let installAction = NSLocalizedString("Install Jetpack", comment: "Title of install action in the Jetpack benefits view.")
        static let notNowAction = NSLocalizedString("Not now", comment: "Title of dismiss action in the Jetpack benefits view.")
        static let pushNotificationsBenefitTitle =
        NSLocalizedString("Push Notifications",
                          comment: "Title of push notifications as part of Jetpack benefits.")
        static let pushNotificationsBenefitSubtitle =
        NSLocalizedString("Get push notifications for new orders, reviews, etc. delivered to your device.",
                          comment: "Subtitle of push notifications as part of Jetpack benefits.")
        static let analyticsBenefitTitle = NSLocalizedString("Analytics", comment: "Title of analytics as part of Jetpack benefits.")
        static let analyticsBenefitSubtitle =
        NSLocalizedString("New analytics views, let you see visitors, reports and more.",
                          comment: "Subtitle of analytics as part of Jetpack benefits.")
        static let userProfilesBenefitTitle = NSLocalizedString("User Profiles", comment: "Title of user profiles as part of Jetpack benefits.")
        static let userProfilesBenefitSubtitle =
        NSLocalizedString("Allow multiple users to access WooCommerce Mobile.",
                          comment: "Subtitle of user profiles as part of Jetpack benefits.")
        static let multiStoresBenefitTitle = NSLocalizedString("Multiple Stores", comment: "Title of multiple stores as part of Jetpack benefits.")
        static let multiStoresBenefitSubtitle =
        NSLocalizedString("Get access to all of your WooCommerce stores.",
                          comment: "Subtitle of multiple stores as part of Jetpack benefits.")
        static let loginAction = NSLocalizedString("Log In to Continue", comment: "Button to start the WPCom login flow from the Jetpack benefits screen.")
        static let dismissAction = NSLocalizedString("Dismiss", comment: "Button to dismiss the Jetpack benefits screen.")
        static let wpAdminAction = NSLocalizedString(
            "Open wp-admin",
            comment: "Button to open the wp-admin page to install Jetpack from the Jetpack benefits screen."
        )
    }
}

struct JetpackBenefits_Previews: PreviewProvider {
    static var previews: some View {
        JetpackBenefitsView(viewModel: .init(siteURL: "https://example.com", isJetpackCPSite: true))
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 414, height: 780))
        JetpackBenefitsView(viewModel: .init(siteURL: "https://example.com", isJetpackCPSite: false))
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 800, height: 300))
    }
}
