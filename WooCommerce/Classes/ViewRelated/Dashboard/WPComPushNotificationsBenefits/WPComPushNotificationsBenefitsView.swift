import SwiftUI
import UIKit
import WooFoundation

/// Hosting controller wrapper for `WPComPushNotificationsBenefitsView`
///
final class WPComPushNotificationsBenefitsHostingController: UIHostingController<WPComPushNotificationsBenefitsView> {

    init(viewModel: WPComPushNotificationsBenefitsViewModel,
         rootViewController: UIViewController) {
        super.init(rootView: WPComPushNotificationsBenefitsView(viewModel: viewModel))
        let coordinator = WooPushNotificationSetupCoordinator(rootViewController: rootViewController)
        viewModel.updateCoordinator(coordinator)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WPComPushNotificationsBenefitsView: View {
    private let viewModel: WPComPushNotificationsBenefitsViewModel

    @State private var safariURL: URL?

    init(viewModel: WPComPushNotificationsBenefitsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                Spacer()
                VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                    stackedImages
                    title
                    detail
                }
                Spacer()
                footer
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
        }
        .onAppear {
            viewModel.onAppear()
        }
        .environment(\.openURL, OpenURLAction { [viewModel] url in
            viewModel.whatIsWPComTapped()
            safariURL = url
            return .handled
        })
        .safariSheet(url: $safariURL)
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
            Text(Localization.subdescription)
                .font(.body)
            Link(Localization.whatIsWPCom, destination: WooConstants.URLs.whatIsWPCom.asURL())
                .font(.body)
                .foregroundColor(Color(UIColor.accent))
        }
    }

    private var footer: some View {
        VStack {
            Button(Localization.continueButton) {
                viewModel.continueTapped()
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(Localization.notNowButton) {
                viewModel.notNowTapped()
            }
            .buttonStyle(SecondaryButtonStyle())
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
                                             comment: "This is the main title displayed on a promotional screen that encourages users to connect their WooCommerce store to a WordPress.com account to enable push notifications. It appears as a headline on the WordPress.com Push Notifications Benefits view that explains the advantages of linking accounts.")

        static let description = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.description",
            value: "Connect your store to a WordPress.com account to get access to push notifications for new orders, reviews and more.",
            comment: "This text appears as the main description in a benefits view that explains the advantages of connecting a WooCommerce store to a WordPress.com account. It is displayed as body text on a promotional screen encouraging users to enable push notifications for store activities."
        )

        static let subdescription = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.subdescription",
            value: "It only takes a minute.",
            comment: "This text appears as a secondary description below the main explanation in a benefits screen that encourages users to connect their WooCommerce store to WordPress.com for push notifications. It reassures users that the connection process is quick and easy."
        )

        static let whatIsWPCom = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.whatIsWPCom",
            value: "What is WordPress.com?",
            comment: "Link text that appears on the WordPress.com Push Notifications Benefits screen, allowing users to tap and learn more about what WordPress.com is. This is displayed as a clickable link below the main description explaining the benefits of connecting to WordPress.com for push notifications."
        )

        static let continueButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.continueButton",
            value: "Continue",
            comment: "This is the label for a primary action button in the WordPress.com Push Notifications Benefits screen that allows users to proceed with connecting their WooCommerce store to WordPress.com to enable push notifications."
        )

        static let notNowButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.notNowButton",
            value: "Not now",
            comment: "This text appears on a button in the WordPress.com Push Notifications Benefits view that allows users to decline or postpone setting up push notifications without completely canceling the process."
        )

        static let cancelButton = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.cancelButton",
            value: "Cancel",
            comment: "This is a cancel button displayed in the toolbar of the WordPress.com Push Notifications Benefits View, which appears when users are being introduced to push notification features. The button allows users to dismiss or exit this benefits explanation screen."
        )
    }
}

#Preview {
    WPComPushNotificationsBenefitsView(
        viewModel: WPComPushNotificationsBenefitsViewModel(onDismiss: {})
    )
}
