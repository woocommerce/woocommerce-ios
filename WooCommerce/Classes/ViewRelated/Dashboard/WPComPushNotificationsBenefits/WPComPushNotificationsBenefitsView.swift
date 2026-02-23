import SwiftUI
import UIKit
import WooFoundation

/// Hosting controller wrapper for `WPComPushNotificationsBenefitsView`
///
final class WPComPushNotificationsBenefitsHostingController: UIHostingController<WPComPushNotificationsBenefitsView> {

    init(viewModel: WPComPushNotificationsBenefitsViewModel,
         rootViewController: UIViewController,
         onSetupCompleted: (() -> Void)? = nil) {
        super.init(rootView: WPComPushNotificationsBenefitsView(viewModel: viewModel))
        let coordinator = WooPushNotificationSetupCoordinator(rootViewController: rootViewController,
                                                              onSetupCompleted: onSetupCompleted)
        viewModel.updateCoordinator(coordinator)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

struct WPComPushNotificationsBenefitsView: View {
    private var viewModel: WPComPushNotificationsBenefitsViewModel

    @State private var safariURL: URL?
    @State private var showSupport = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: WPComPushNotificationsBenefitsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let error = viewModel.error {
                    VStack(spacing: Layout.contentSpacing) {
                        errorView(with: error)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        Spacer()
                        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                            stackedImages
                            title
                            detail
                        }
                        Spacer()
                    }
                    .redacted(reason: viewModel.isCheckingPlugin ? .placeholder : [])
                    .shimmering(active: viewModel.isCheckingPlugin)
                }

                if dynamicTypeSize.isAccessibilitySize && !viewModel.isCheckingPlugin {
                    footer
                }
            }
            .padding([.leading, .bottom, .trailing], Layout.contentPadding)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        viewModel.notNowTapped()
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                footer
                    .padding(Layout.contentPadding)
                    .background(Color(uiColor: .systemBackground))
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize && !viewModel.isCheckingPlugin)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .task {
            await viewModel.determineSetupVariant()
        }
        .environment(\.openURL, OpenURLAction { [viewModel] url in
            viewModel.whatIsWPComTapped()
            safariURL = url
            return .handled
        })
        .safariSheet(url: $safariURL)
        .sheet(isPresented: $showSupport, content: { supportForm })
    }

    private var stackedImages: some View {
        Image(uiImage: .connectWPComImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: Layout.logoHeight)
    }

    private var title: some View {
        Text(Localization.title)
            .font(.largeTitle)
            .fontWeight(.bold)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            Text(Localization.description)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(Localization.subdescription)
                .font(.body)
            Link(Localization.whatIsWPCom, destination: WooConstants.URLs.whatIsWPCom.asURL())
                .font(.body)
                .foregroundColor(Color(UIColor.accent))
        }
    }

    private var footer: some View {
        VStack {
            if viewModel.error != nil {
                Button(Localization.contactSupport) {
                    showSupport = true
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(primaryButtonText) {
                    viewModel.continueTapped()
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            Button(Localization.notNowButton) {
                viewModel.notNowTapped()
            }
            .buttonStyle(SecondaryButtonStyle())

            if case .connect = viewModel.variant, viewModel.error == nil {
                Text(viewModel.termsAttributedString)
            }
        }
    }

    private var primaryButtonText: String {
        switch viewModel.variant {
        case .connect:
            return Localization.continueButton
        case .pluginUpdate:
            return Localization.updatePluginButton
        }
    }

    private func errorView(with error: WPComPushNotificationsBenefitsViewModel.VariantCheckError) -> some View {
        VStack(spacing: Layout.contentPadding) {
            Spacer()
            Image(systemName: "exclamationmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color(.error))
            Text(Localization.errorTitle)
                .font(.title)
            Text(error.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
        }
    }

    private var supportForm: some View {
        NavigationStack {
            SupportForm(
                isPresented: $showSupport,
                viewModel: SupportFormViewModel(sourceTag: WPComConnectionSetupViewModel.supportSourceTag)
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        showSupport = false
                    }
                }
            }
        }
    }
}

fileprivate extension WPComPushNotificationsBenefitsView {
    enum Layout {
        static let logoHeight: CGFloat = 64
        static let contentSpacing: CGFloat = 24
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString("wpcomPushNotificationsBenefitsView.title",
                                             value: "Unlock push notifications with WordPress.com",
                                             comment: "Title of the WordPress.com Push Notifications Benefits View")

        static let description = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.mainDescription",
            value: "Connect your store to WordPress.com to get access to push notifications for new orders, reviews and more.",
            comment: "Main description text of the WordPress.com Push Notifications Benefits View"
        )

        static let subdescription = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.subdescription",
            value: "It only takes a minute.",
            comment: "Secondary description text of the WordPress.com Push Notifications Benefits View"
        )

        static let whatIsWPCom = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.whatIsWPCom",
            value: "What is WordPress.com?",
            comment: "Link text explaining what WordPress.com is in the Push Notifications Benefits View"
        )

        static let continueButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.continueButton",
            value: "Continue",
            comment: "Continue button title in the WordPress.com Push Notifications Benefits View"
        )

        static let notNowButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.notNowButton",
            value: "Not now",
            comment: "Not now button title in the WordPress.com Push Notifications Benefits View"
        )

        static let cancelButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.cancelButton",
            value: "Cancel",
            comment: "Cancel button title in the WordPress.com Push Notifications Benefits View toolbar"
        )

        static let updatePluginButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.updatePluginButton",
            value: "Update plugin",
            comment: "Button title to update the WooCommerce plugin in the Push Notifications Benefits View"
        )

        static let errorTitle = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.errorTitle",
            value: "Something went wrong",
            comment: "Title of the error state in the Push Notifications Benefits View"
        )

        static let contactSupport = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.contactSupport",
            value: "Contact support",
            comment: "Button title to contact support in the Push Notifications Benefits View"
        )
    }
}

#Preview {
    WPComPushNotificationsBenefitsView(
        viewModel: WPComPushNotificationsBenefitsViewModel(siteID: 0, siteURL: "https://example.com", onDismiss: {})
    )
}
