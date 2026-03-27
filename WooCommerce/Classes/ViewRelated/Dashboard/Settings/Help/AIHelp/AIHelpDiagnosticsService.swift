import Foundation
import Yosemite
import UserNotifications

/// Runs automated diagnostic checks for common issues.
///
@MainActor
struct AIHelpDiagnosticsService {

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    // MARK: - Analytics

    /// Checks whether WooCommerce Analytics is enabled for the site.
    /// - Returns: `true` if analytics is enabled, `false` otherwise.
    ///
    func checkAnalyticsSetting(siteID: Int64) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let action = SettingAction.retrieveAnalyticsSetting(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    /// Enables WooCommerce Analytics for the site.
    ///
    func enableAnalyticsSetting(siteID: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = SettingAction.enableAnalyticsSetting(siteID: siteID) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    // MARK: - Orders

    /// Attempts to sync a single order to verify order loading is working.
    /// - Returns: `true` if orders were loaded successfully.
    ///
    func checkOrderSync(siteID: Int64) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.fetchFilteredOrders(
                siteID: siteID,
                statuses: nil,
                after: nil,
                before: nil,
                modifiedAfter: nil,
                customerID: nil,
                productID: nil,
                createdVia: nil,
                writeStrategy: .doNotSave,
                pageSize: 1
            ) { _, result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }

    // MARK: - Products

    /// Attempts to sync a single product to verify product loading is working.
    /// - Returns: `true` if products were loaded successfully.
    ///
    func checkProductSync(siteID: Int64) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let action = ProductAction.synchronizeProducts(
                siteID: siteID,
                pageNumber: 1,
                pageSize: 1,
                stockStatus: nil,
                productStatus: nil,
                productType: nil,
                productCategory: nil,
                sortOrder: .dateDescending,
                shouldDeleteStoredProductsOnFirstPage: false
            ) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }

    // MARK: - Notifications

    /// Checks whether push notification permissions are granted.
    ///
    func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Checks whether the user is authenticated with WordPress.com.
    ///
    func isAuthenticatedWithWPCom() -> Bool {
        !stores.isAuthenticatedWithoutWPCom
    }

    /// Checks Jetpack plugin status for the site.
    /// - Returns: A description of the Jetpack status.
    ///
    func checkJetpackStatus(siteID: Int64) async -> String {
        let site = stores.sessionManager.defaultSite
        if let site, site.isJetpackThePluginInstalled, site.isJetpackConnected {
            return Localization.jetpackActive
        } else if let site, site.isJetpackThePluginInstalled {
            return Localization.jetpackInstalledNotConnected
        } else {
            return Localization.jetpackNotInstalled
        }
    }

    // MARK: - Notification Settings

    /// Result of checking notification settings for a site.
    ///
    struct NotificationSettingsResult {
        let ordersEnabled: Bool
        let reviewsEnabled: Bool
    }

    /// Loads notification settings for the current device and site.
    /// - Returns: The notification settings for the site, or `nil` if unavailable.
    ///
    func loadNotificationSettings(siteID: Int64) async throws -> NotificationSettingsResult? {
        guard let deviceIDString = ServiceLocator.pushNotesManager.deviceID,
              let deviceID = Int64(deviceIDString) else {
            return nil
        }

        let settings: NotificationSettings = try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.loadNotificationSettings(deviceID: deviceID) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }

        guard let blog = settings.blogs.first(where: { $0.blogID == siteID }),
              let device = blog.devices.first(where: { $0.deviceID == deviceID }) else {
            return nil
        }

        return NotificationSettingsResult(ordersEnabled: device.storeOrder, reviewsEnabled: device.newComment)
    }

    /// Enables order and/or review notifications for a site.
    ///
    func enableNotifications(siteID: Int64, enableOrders: Bool, enableReviews: Bool) async throws {
        guard let deviceIDString = ServiceLocator.pushNotesManager.deviceID,
              let deviceID = Int64(deviceIDString) else {
            return
        }

        let settings: NotificationSettings = try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.loadNotificationSettings(deviceID: deviceID) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }

        let updatedBlogs = settings.blogs.map { blog -> NotificationSettings.Blog in
            guard blog.blogID == siteID else { return blog }
            let updatedDevices = blog.devices.map { device -> NotificationSettings.Device in
                guard device.deviceID == deviceID else { return device }
                return device.copy(newComment: enableReviews ? true : device.newComment,
                                   storeOrder: enableOrders ? true : device.storeOrder)
            }
            return blog.copy(devices: updatedDevices)
        }

        let updatedSettings = NotificationSettings(blogs: updatedBlogs)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let action = AccountAction.updateNotificationSettings(notificationSettings: updatedSettings) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    // MARK: - AI Text Generation

    /// Uses Jetpack AI to analyze the user's problem description and suggest troubleshooting steps.
    ///
    func analyzeUserInput(siteID: Int64, input: String, topic: AIHelpTroubleshootingOption) async throws -> String {
        let prompt = """
        You are a helpful support assistant for WooCommerce mobile app users. \
        The user is experiencing an issue related to: \(topic.title). \
        Their description: "\(input)". \
        Please provide 2-3 concise, actionable troubleshooting steps they can try. \
        Keep your response brief and user-friendly. \
        If the issue seems complex, suggest contacting support. \
        Translate your response to match the user's language if their input is not in English.
        """

        return try await withCheckedThrowingContinuation { continuation in
            let action = GenerativeContentAction.generateText(
                siteID: siteID,
                base: prompt,
                feature: .supportTroubleshooting,
                responseFormat: .text
            ) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }
}

// MARK: - Localization
//
private extension AIHelpDiagnosticsService {
    enum Localization {
        static let jetpackActive = NSLocalizedString(
            "aiHelp.diagnostics.jetpackActive",
            value: "Jetpack is installed and connected.",
            comment: "Diagnostic result when Jetpack plugin is active and connected"
        )
        static let jetpackInstalledNotConnected = NSLocalizedString(
            "aiHelp.diagnostics.jetpackInstalledNotConnected",
            value: "Jetpack is installed but not connected. Please connect Jetpack in your site's admin.",
            comment: "Diagnostic result when Jetpack is installed but not connected"
        )
        static let jetpackNotInstalled = NSLocalizedString(
            "aiHelp.diagnostics.jetpackNotInstalled",
            value: "Jetpack is not installed. Notifications require the Jetpack plugin.",
            comment: "Diagnostic result when Jetpack plugin is not installed"
        )
    }
}
