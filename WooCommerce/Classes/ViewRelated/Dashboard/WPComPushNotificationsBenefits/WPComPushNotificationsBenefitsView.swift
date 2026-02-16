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
    private let viewModel: WPComPushNotificationsBenefitsViewModel

    @State private var safariURL: URL?

    init(viewModel: WPComPushNotificationsBenefitsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
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
                                             comment: "Title of the WordPress.com Push Notifications Benefits View")

        static let description = NSLocalizedString(
            "wpcomPushNotificationsBenefitsView.description",
            value: "Connect your store to a WordPress.com account to get access to push notifications for new orders, reviews and more.",
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
    }
}

#Preview {
    WPComPushNotificationsBenefitsView(
        viewModel: WPComPushNotificationsBenefitsViewModel(onDismiss: {})
    )
}
