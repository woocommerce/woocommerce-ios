import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics
import enum NetworkingCore.NetworkError

@MainActor
@Observable
final class WPComPushNotificationsBenefitsViewModel {

    enum Variant: Equatable {
        case connect
        case pluginUpdate(currentVersion: String)
    }

    let termsAttributedString: AttributedString

    var title: String {
        switch variant {
        case .connect: Localization.connectWPComTitle
        case .pluginUpdate: Localization.updatePluginTitle
        }
    }

    var description: String {
        switch variant {
        case .connect: Localization.connectWPComDescription
        case .pluginUpdate: Localization.updatePluginDescription
        }
    }

    private(set) var variant: Variant = .connect
    private(set) var isCheckingPlugin: Bool = false
    private(set) var error: VariantCheckError?

    private let stores: StoresManager
    private let analytics: Analytics
    private let onDismiss: () -> Void
    private let jetpackConnectionService: JetpackConnectionServiceProtocol
    private let pluginVersionChecker: PluginVersionCheckerProtocol

    private var pushNotificationSetupCoordinator: WooPushNotificationSetupCoordinator?

    init(siteID: Int64,
         siteURL: String,
         stores: StoresManager = ServiceLocator.stores,
         jetpackConnectionService: JetpackConnectionServiceProtocol = JetpackConnectionService(),
         pluginVersionChecker: PluginVersionCheckerProtocol? = nil,
         analytics: Analytics = ServiceLocator.analytics,
         onDismiss: @escaping () -> Void) {
        self.stores = stores
        self.jetpackConnectionService = jetpackConnectionService
        self.analytics = analytics
        self.onDismiss = onDismiss
        let minimumVersion: String = {
        #if DEBUG
            if let override: String = UserDefaults.standard[.debugMinWooVersionForSelfDrivenPushNotifications],
               !override.isEmpty {
                return override
            }
        #endif
            return WooPluginRequirements.minimumVersion
        }()
        self.pluginVersionChecker = pluginVersionChecker ?? PluginVersionChecker(
            siteID: siteID,
            pluginPath: WooPluginRequirements.pluginPath,
            minimumVersion: minimumVersion
        )

        self.termsAttributedString = {
            let content = String.localizedStringWithFormat(Localization.termsContent, Localization.termsOfService, Localization.shareDetails)

            let attributedText = AttributedString.withEmbeddedLinks(
                content: content,
                links: [
                    Localization.termsOfService: Constants.jetpackTermsURL + siteURL,
                    Localization.shareDetails: Constants.jetpackShareDetailsURL + siteURL
                ],
                font: .footnote,
                foregroundColor: .secondary
            )
            return attributedText
        }()
    }

    func updateCoordinator(_ coordinator: WooPushNotificationSetupCoordinator) {
        self.pushNotificationSetupCoordinator = coordinator
    }

    /// Fetches Jetpack connection data to determine whether the site is connected,
    /// then checks the WooCommerce plugin version if Jetpack is connected.
    func determineSetupVariant() async {
        isCheckingPlugin = true
        defer {
            isCheckingPlugin = false
        }

        /// Skip Jetpack connection check if site is JCP
        guard stores.sessionManager.defaultSite?.isJetpackCPConnected == false else {
            return await checkWooPluginVersion()
        }

        do {
            let connectionData = try await jetpackConnectionService.fetchConnectionData()
            /// only site-connection is required for Woo PN
            /// ref: C03L1NF1EA3-slack-p1771522327596419
            if connectionData.isRegistered == true {
                await checkWooPluginVersion()
            } else {
                variant = .connect
                analytics.track(event: .WPComPushNotificationsSetup.introductionView(state: .notConnected))
            }
        } catch {
            DDLogError("⛔️ Failed to fetch Jetpack connection data: \(error)")
            if case NetworkError.unacceptableStatusCode(403, _) = error {
                self.error = .noPermission
                analytics.track(.pushNotificationsSetupIntroductionError, withProperties: ["error_type": "no_permission"])
            } else {
                self.error = .generic(underlyingError: error)
                analytics.track(.pushNotificationsSetupIntroductionError, properties: ["error_type": "generic"], error: error)
            }
        }
    }

    func continueTapped() {
        switch variant {
        case .connect:
            analytics.track(event: .WPComPushNotificationsSetup.introductionButtonTap(.continue))
            pushNotificationSetupCoordinator?.startSetup(siteAlreadyConnected: false)
        case .pluginUpdate(let currentVersion):
            analytics.track(event: .WPComPushNotificationsSetup.introductionButtonTap(.updatePlugin))
            pushNotificationSetupCoordinator?.startSetup(
                siteAlreadyConnected: true,
                pluginOutdatedVersion: currentVersion
            )
        }
    }

    func notNowTapped() {
        analytics.track(event: .WPComPushNotificationsSetup.introductionButtonTap(.notNow))
        onDismiss()
    }

    func cancelTapped() {
        analytics.track(.pushNotificationsSetupIntroductionClose)
        onDismiss()
    }

    func onSwipeDismiss() {
        analytics.track(.pushNotificationsSetupIntroductionClose)
    }

    func whatIsWPComTapped() {
        analytics.track(.pushNotificationsSetupIntroductionLinkTap)
    }
}

// MARK: - Plugin version check

private extension WPComPushNotificationsBenefitsViewModel {
    func checkWooPluginVersion() async {
        do {
            let result = try await pluginVersionChecker.checkCompatibility()
            if case .incompatible(let currentVersion, _) = result {
                variant = .pluginUpdate(currentVersion: currentVersion)
                analytics.track(event: .WPComPushNotificationsSetup.introductionView(state: .updateRequired))
            } else {
                error = .noMissingRequirements
                analytics.track(.pushNotificationsSetupIntroductionError, properties: ["error_type": "generic"], error: error)
            }
        } catch {
            DDLogError("⛔️ Plugin version check failed: \(error)")
            self.error = .generic(underlyingError: error)
            analytics.track(.pushNotificationsSetupIntroductionError, properties: ["error_type": "generic"], error: error)
        }
    }
}

extension WPComPushNotificationsBenefitsViewModel {
    enum VariantCheckError: Error {
        case noPermission
        case noMissingRequirements
        case generic(underlyingError: Error)

        var message: String {
            switch self {
            case .noPermission:
                Localization.noPermission
            case .noMissingRequirements, .generic:
                Localization.generic
            }
        }

        enum Localization {
            static let noPermission = NSLocalizedString(
                "wpcomPushNotificationsBenefitsViewModel.variantCheckError.noPermission",
                value: "Your account does not have permission to complete push notifications setup. " +
                "Please ask your store administrator to handle this.",
                comment: "Error message in the Push Notifications Benefits View for users without admin role"
            )
            static let generic = NSLocalizedString(
                "wpcomPushNotificationsBenefitsViewModel.variantCheckError.generic",
                value: "We could not complete the push notifications setup. " +
                "Please contact support for assistance.",
                comment: "Generic error message in the Push Notifications Benefits View"
            )
        }
    }

    private enum Constants {
        static let jetpackTermsURL = "https://jetpack.com/redirect/?source=wpcom-tos&site="
        static let jetpackShareDetailsURL = "https://jetpack.com/redirect/?source=jetpack-support-what-data-does-jetpack-sync&site="
    }

    enum Localization {
        static let termsContent = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.termsContent",
            value: "By continuing, you agree to our %1$@ and to %2$@ with WordPress.com.",
            comment: "Content of the label at the end of the Wrong Account screen. " +
            "Reads like: By continuing, you agree to our Terms of Service and to share details with WordPress.com."
        )
        static let termsOfService = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.termsOfService",
            value: "Terms of Service",
            comment: "The terms to be agreed upon when tapping the Continue button on the Push Notifications Benefits View."
        )
        static let shareDetails = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.shareDetails",
            value: "share details",
            comment: "The action to be agreed upon when tapping the Continue button on the Push Notifications Benefits View."
        )

        static let connectWPComTitle = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.title",
            value: "Unlock push notifications with WordPress.com",
            comment: "Title of the WordPress.com Push Notifications Benefits View"
        )

        static let connectWPComDescription = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.mainDescription",
            value: "Connect your store to WordPress.com to get access to push notifications for new orders, reviews and more.",
            comment: "Main description text of the WordPress.com Push Notifications Benefits View"
        )

        static let updatePluginTitle = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.updatePluginTitle",
            value: "Get push notifications for your store",
            comment: "Title of the Push Notifications Benefits View when WooCommerce plugin is outdated"
        )

        static let updatePluginDescription = NSLocalizedString(
            "wpcomPushNotificationsBenefitsViewModel.updatePluginDescription",
            value: "Your store is already connected to a WordPress.com account, but you’ll need to " +
            "update WooCommerce plugin to enable push notifications for new orders, reviews, and more.",
            comment: "Description text on the Push Notifications Benefits View when WooCommerce plugin is outdated"
        )
    }
}
