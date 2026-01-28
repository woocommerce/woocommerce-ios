import SwiftUI
import UIKit
import WooFoundation

/// Hosting controller wrapper for `WPComPushNotificationsBenefitsView`
///
final class WPComPushNotificationsBenefitsHostingController: UIHostingController<WPComPushNotificationsBenefitsView> {
    private var pushNotificationSetupCoordinator: WooPushNotificationSetupCoordinator?

    init(viewModel: WPComPushNotificationsBenefitsViewModel,
         onDismiss: @escaping () -> Void) {
        super.init(rootView: WPComPushNotificationsBenefitsView(
            viewModel: viewModel,
            onDismiss: onDismiss
        ))
        rootView.onSetup = { [weak self] in
            self?.startPushNotificationSetup()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startPushNotificationSetup() {
        guard let navigationController else { return }
        let coordinator = WooPushNotificationSetupCoordinator(
            navigationController: navigationController
        )
        pushNotificationSetupCoordinator = coordinator
        coordinator.start()
    }
}

struct WPComPushNotificationsBenefitsView: View {
    var onSetup: () -> Void = {} // to be set through hosting controller

    private let viewModel: WPComPushNotificationsBenefitsViewModel
    private let onDismiss: () -> Void

    @State private var safariURL: URL?

    init(viewModel: WPComPushNotificationsBenefitsViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
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
                    onDismiss()
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
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
                onSetup()
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(Localization.notNowButton) {
                viewModel.notNowTapped()
                onDismiss()
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
        viewModel: WPComPushNotificationsBenefitsViewModel(),
        onDismiss: {}
    )
}
