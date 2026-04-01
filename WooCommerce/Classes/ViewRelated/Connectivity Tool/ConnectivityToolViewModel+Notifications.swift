import Foundation
import UIKit
import Yosemite
import enum Networking.SitePluginStatusEnum
import protocol WooFoundation.Analytics
import UserNotifications

// MARK: - Notifications Check

extension ConnectivityToolViewModel {

    /// Test notification settings: Jetpack plugin status, iOS permission, and notification config.
    ///
    @MainActor
    func testNotifications() async -> ConnectivityToolCard.ConnectivityState {
        // Sub-check 1: Jetpack plugin is active.
        let jetpackResult = await checkJetpackPluginActiveIfNeeded()
        if case .failure(let error) = jetpackResult {
            DDLogError("Connectivity Tool: ❌ Jetpack plugin check failed\n\(error)")
            let setupJetpackAction = ConnectivityToolCard.ConnectivityState.Action(
                title: Localization.Action.setupJetpack,
                systemImage: SystemImages.setupJetpack.rawValue,
                action: { [weak self] in
                    self?.shouldStartJetpackSetup = true
                }
            )
            return .error(Localization.ErrorMessage.jetpackPluginNotActive, [setupJetpackAction, retryAction(for: .notifications)])
        }

        // Sub-check 2: iOS notification permission is authorized.
        let permissionResult = await checkNotificationPermission()
        if case .failure = permissionResult {
            DDLogInfo("Connectivity Tool: ⚠️ Notifications not authorized")
            let openSettingsAction = ConnectivityToolCard.ConnectivityState.Action(
                title: Localization.Action.openSettings,
                systemImage: SystemImages.openSettings.rawValue,
                action: { [weak self] in
                    self?.selectedURL = URL(string: UIApplication.openNotificationSettingsURLString)
                }
            )
            return .error(Localization.ErrorMessage.notificationsNotAuthorized, [openSettingsAction, retryAction(for: .notifications)])
        }

        // Sub-check 3: Notification config — device registered and order notifications enabled.
        let configResult = await checkNotificationConfig()
        switch configResult {
        case .success:
            DDLogInfo("Connectivity Tool: ✅ Notification settings configured")
            return .success
        case .failure(let configError):
            DDLogInfo("Connectivity Tool: ⚠️ Notification config issue: \(configError)")
            switch configError {
            case .deviceNotRegistered:
                let registerAction = ConnectivityToolCard.ConnectivityState.Action(
                    title: Localization.Action.registerDevice,
                    systemImage: SystemImages.enableAction.rawValue,
                    action: { [weak self] in
                        self?.registerDeviceForNotifications()
                    }
                )
                return .error(Localization.ErrorMessage.deviceNotRegistered, [registerAction])
            case .orderNotificationsDisabled(let settings):
                let enableAction = ConnectivityToolCard.ConnectivityState.Action(
                    title: Localization.Action.enableOrderNotifications,
                    systemImage: SystemImages.enableAction.rawValue,
                    action: { [weak self] in
                        self?.enableOrderNotifications(settings: settings)
                    }
                )
                return .error(Localization.ErrorMessage.orderNotificationsDisabled,
                              [enableAction, retryAction(for: .notifications)])
            case .requestFailed(let error):
                let technicalDetails = String(describing: error)
                let viewDetailsAction = ConnectivityToolCard.ConnectivityState.Action(
                    title: Localization.Action.viewDetails,
                    systemImage: SystemImages.viewDetails.rawValue,
                    technicalDetails: technicalDetails
                )
                return .error(Localization.ErrorMessage.notificationConfigCheckFailed,
                              [viewDetailsAction, retryAction(for: .notifications)])
            }
        }
    }

    /// Authenticates and retrieves the Jetpack plugin details to verify it's active.
    ///
    @MainActor
    func checkJetpackPluginActiveIfNeeded() async -> Result<Void, JetpackCheckError> {
        /// WPCom and CIAB sites have Jetpack by default so skip this check
        guard stores.sessionManager.defaultSite?.isWordPressComStore == false,
              stores.sessionManager.defaultSite?.isCIAB == false else {
            return .success(())
        }

        /// Authenticate the JetpackConnectionStore with current network.
        if let siteURL {
            stores.dispatch(JetpackConnectionAction.authenticate(siteURL: siteURL, network: network))
        }

        return await withCheckedContinuation { continuation in
            let action = JetpackConnectionAction.retrieveJetpackPluginDetails(siteID: siteID) { result in
                switch result {
                case .success(let plugin):
                    if plugin.status == .active || plugin.status == .networkActive {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(.pluginNotActive(status: plugin.status)))
                    }
                case .failure(let error):
                    continuation.resume(returning: .failure(.requestFailed(error)))
                }
            }
            stores.dispatch(action)
        }
    }

    /// Checks the iOS notification authorization status.
    ///
    func checkNotificationPermission() async -> Result<Void, NotificationPermissionError> {
        await withCheckedContinuation { continuation in
            userNotificationCenter.loadAuthorizationStatus(queue: .main) { status in
                if status == .authorized {
                    continuation.resume(returning: .success(()))
                } else {
                    continuation.resume(returning: .failure(.notAuthorized(status: status)))
                }
            }
        }
    }

    /// Checks that the device is registered for notifications and order notifications are enabled.
    ///
    @MainActor
    func checkNotificationConfig() async -> Result<Void, NotificationConfigError> {
        guard let deviceID = pushNotesManager.deviceID,
              let numericDeviceID = Int64(deviceID) else {
            return .failure(.deviceNotRegistered)
        }

        return await withCheckedContinuation { continuation in
            let action = AccountAction.loadNotificationSettings(deviceID: numericDeviceID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let settings):
                    guard let blog = settings.blogs.first(where: { $0.blogID == self.siteID }),
                          let device = blog.devices.first(where: { $0.deviceID == numericDeviceID }),
                          device.storeOrder else {
                        continuation.resume(returning: .failure(.orderNotificationsDisabled(settings: settings)))
                        return
                    }
                    continuation.resume(returning: .success(()))
                case .failure(let error):
                    continuation.resume(returning: .failure(.requestFailed(error)))
                }
            }
            stores.dispatch(action)
        }
    }

    /// Enables order notifications for the current site and device.
    ///
    func enableOrderNotifications(settings: NotificationSettings) {
        guard let deviceID = pushNotesManager.deviceID,
              let numericDeviceID = Int64(deviceID) else { return }

        // Show loading indicator while enabling.
        updateCardState(for: .notifications, state: .inProgress)

        // Build updated settings with storeOrder enabled for this device/blog.
        let updatedBlogs: [NotificationSettings.Blog] = settings.blogs.map { blog in
            guard blog.blogID == siteID else { return blog }
            let updatedDevices: [NotificationSettings.Device] = blog.devices.map { device in
                guard device.deviceID == numericDeviceID else { return device }
                return device.copy(storeOrder: true)
            }
            return blog.copy(devices: updatedDevices)
        }
        let updatedSettings = settings.copy(blogs: updatedBlogs)

        let action = AccountAction.updateNotificationSettings(notificationSettings: updatedSettings) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                DDLogInfo("Connectivity Tool: ✅ Order notifications enabled successfully")
                self.updateCardState(for: .notifications, state: .success)
            case .failure(let error):
                DDLogError("Connectivity Tool: ❌ Failed to enable order notifications\n\(error)")
                self.restoreNotificationsCardActions(settings: settings)
            }
        }
        stores.dispatch(action)
    }

    /// Registers the device for push notifications and re-runs the notifications check.
    ///
    func registerDeviceForNotifications() {
        // Show loading indicator while registering.
        updateCardState(for: .notifications, state: .inProgress)

        Task { @MainActor in
            do {
                _ = try await pushNotesManager.registerDeviceAndWaitForTokenAcceptance()
                DDLogInfo("Connectivity Tool: ✅ Device registered for push notifications")
            } catch {
                DDLogError("Connectivity Tool: ❌ Failed to register device for push notifications\n\(error)")
            }
            // Re-run the full notifications check regardless of outcome.
            let state = await testNotifications()
            updateCardState(for: .notifications, state: state)
        }
    }

    /// Restores the notifications card to its interactive error state after a failed enable attempt.
    ///
    private func restoreNotificationsCardActions(settings: NotificationSettings) {
        let enableAction = ConnectivityToolCard.ConnectivityState.Action(
            title: Localization.Action.enableOrderNotifications,
            systemImage: SystemImages.enableAction.rawValue,
            action: { [weak self] in
                self?.enableOrderNotifications(settings: settings)
            }
        )
        updateCardState(for: .notifications,
                        state: .error(Localization.ErrorMessage.orderNotificationsDisabled,
                                      [enableAction, retryAction(for: .notifications)]))
    }

    /// Error types for the Jetpack plugin check.
    ///
    enum JetpackCheckError: Error {
        case pluginNotActive(status: SitePluginStatusEnum)
        case requestFailed(Error)
    }

    /// Error types for the notification permission check.
    ///
    enum NotificationPermissionError: Error {
        case notAuthorized(status: UNAuthorizationStatus)
    }

    /// Error types for the notification config check.
    ///
    enum NotificationConfigError: Error {
        case deviceNotRegistered
        case orderNotificationsDisabled(settings: NotificationSettings)
        case requestFailed(Error)
    }
}

// MARK: - Localization

private extension ConnectivityToolViewModel {
    enum Localization {
        enum ErrorMessage {
            static let jetpackPluginNotActive = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.jetpackPluginNotActive",
                value: "The Jetpack plugin doesn't appear to be active on your site.\n\n" +
                "Push notifications require an active Jetpack connection.",
                comment: "Message when Jetpack plugin is not active in the connectivity tool"
            )
            static let notificationsNotAuthorized = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.notificationsNotAuthorized",
                value: "Push notifications are not allowed for this app.\n\n" +
                "Enable them in your device Settings to receive order notifications.",
                comment: "Message when iOS notification permission is denied in the connectivity tool"
            )
            static let deviceNotRegistered = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.deviceNotRegistered",
                value: "Your device doesn't appear to be registered for push notifications.\n\n" +
                "Try logging out and back in to re-register.",
                comment: "Message when the device is not registered for push notifications in the connectivity tool"
            )
            static let orderNotificationsDisabled = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.orderNotificationsDisabled",
                value: "Order notifications are not enabled for this store.\n\n" +
                "Enable them to receive alerts when new orders come in.",
                comment: "Message when order notifications are disabled in the connectivity tool"
            )
            static let notificationConfigCheckFailed = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.notificationConfigCheckFailed",
                value: "We couldn't check your notification settings.\n\n" +
                "Contact our support team for further assistance.",
                comment: "Message when the notification config check fails in the connectivity tool"
            )
        }
        enum Action {
            static let readMore = NSLocalizedString(
                "connectivityToolViewModel.action.readMore",
                value: "Read more",
                comment: "Action button title for an error on the connectivity tool"
            )
            static let viewDetails = NSLocalizedString(
                "connectivityToolViewModel.action.viewTechnicalDetails",
                value: "View technical details",
                comment: "Button to view technical error details in the connectivity tool"
            )
            static let setupJetpack = NSLocalizedString(
                "connectivityToolViewModel.action.setupJetpack",
                value: "Setup Jetpack",
                comment: "Action button to start the Jetpack setup flow in the connectivity tool"
            )
            static let openSettings = NSLocalizedString(
                "connectivityToolViewModel.action.openSettings",
                value: "Open Settings",
                comment: "Action button to open device notification settings in the connectivity tool"
            )
            static let registerDevice = NSLocalizedString(
                "connectivityToolViewModel.action.registerDevice",
                value: "Register Device",
                comment: "Action button to register the device for push notifications in the connectivity tool"
            )
            static let enableOrderNotifications = NSLocalizedString(
                "connectivityToolViewModel.action.enableOrderNotifications",
                value: "Enable Order Notifications",
                comment: "Action button to enable order notifications in the connectivity tool"
            )
        }
    }

    enum SystemImages: String {
        case viewDetails = "info.circle"
        case enableAction = "checkmark.circle"
        case openSettings = "gear"
        case setupJetpack = "bolt.fill"
    }
}
