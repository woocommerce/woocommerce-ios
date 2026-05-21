import Foundation
import UIKit
import Yosemite
import enum Networking.DotcomError
import class Networking.AlamofireNetwork
import protocol NetworkingCore.Network
import class Networking.AnnouncementsRemote
import class Networking.SystemStatusRemote
import class Networking.OrdersRemote
import class Networking.ProductsRemote
import class Networking.UserAgent
import struct Networking.SystemPlugin
import protocol WooFoundation.Analytics
import protocol WooFoundation.ConnectivityObserver
import UserNotifications

@MainActor
protocol SupportDiagnosticsServicing {
    var formattedSystemStatusReport: String? { get }

    func runTests(_ tests: [SupportDiagnosticsService.Test]) async -> [SupportDiagnosticsService.Result]
    func enableAnalytics() async throws
    func registerDevice() async throws
    func enableOrderNotifications(settings: NotificationSettings) async throws
    func openNotificationSettings() -> URL?
}

/// Service for running diagnostics and executing fix actions in Support Chat.
/// This service is standalone and does not share code with ConnectivityToolViewModel.
///
@MainActor
final class SupportDiagnosticsService {

    // MARK: - Types

    /// Diagnostic tests that can be run.
    ///
    enum Test: String, CaseIterable {
        case internetConnection
        case wpComServers = "wpcomServers"
        case site
        case siteOrders
        case loadingProducts
        case analyticsSetting
        case notifications

        var title: String {
            switch self {
            case .internetConnection:
                return Localization.Test.internetConnection
            case .wpComServers:
                return Localization.Test.wpComServers
            case .site:
                return Localization.Test.site
            case .siteOrders:
                return Localization.Test.siteOrders
            case .loadingProducts:
                return Localization.Test.loadingProducts
            case .analyticsSetting:
                return Localization.Test.analyticsSetting
            case .notifications:
                return Localization.Test.notifications
            }
        }
    }

    /// Actions that can fix diagnostic issues.
    ///
    enum Action: Equatable {
        case enableAnalytics
        case registerDevice
        case enableOrderNotifications(settings: NotificationSettings)
        case setupJetpack
        case updateWooCommercePlugin
        case openNotificationSettings
        case retryDiagnostics

        var title: String {
            switch self {
            case .enableAnalytics:
                return Localization.Action.enableAnalytics
            case .registerDevice:
                return Localization.Action.registerDevice
            case .enableOrderNotifications:
                return Localization.Action.enableOrderNotifications
            case .setupJetpack:
                return Localization.Action.setupJetpack
            case .updateWooCommercePlugin:
                return Localization.Action.updateWooCommercePlugin
            case .openNotificationSettings:
                return Localization.Action.openSettings
            case .retryDiagnostics:
                return Localization.Action.retryDiagnostics
            }
        }

        var systemImage: String {
            switch self {
            case .enableAnalytics, .registerDevice, .enableOrderNotifications:
                return "checkmark.circle"
            case .setupJetpack:
                return "bolt.fill"
            case .updateWooCommercePlugin:
                return "arrow.up.circle"
            case .openNotificationSettings:
                return "gear"
            case .retryDiagnostics:
                return "arrow.clockwise"
            }
        }
    }

    /// Failure details returned by individual test methods.
    ///
    struct Failure {
        let errorMessage: String
        let technicalDetails: String?
        let suggestedAction: Action?

        init(errorMessage: String, technicalDetails: String? = nil, suggestedAction: Action? = nil) {
            self.errorMessage = errorMessage
            self.technicalDetails = technicalDetails
            self.suggestedAction = suggestedAction
        }
    }

    /// Result of a diagnostic test.
    ///
    struct Result: Equatable {
        let test: Test
        let isSuccess: Bool
        let errorMessage: String?
        let technicalDetails: String?
        let suggestedAction: Action?

        static func == (lhs: Result, rhs: Result) -> Bool {
            lhs.test == rhs.test &&
            lhs.isSuccess == rhs.isSuccess &&
            lhs.errorMessage == rhs.errorMessage &&
            lhs.suggestedAction == rhs.suggestedAction
        }

        static func success(test: Test) -> Result {
            Result(test: test, isSuccess: true, errorMessage: nil, technicalDetails: nil, suggestedAction: nil)
        }

        static func failure(test: Test, failure: Failure) -> Result {
            Result(test: test,
                   isSuccess: false,
                   errorMessage: failure.errorMessage,
                   technicalDetails: failure.technicalDetails,
                   suggestedAction: failure.suggestedAction)
        }

        func troubleshootingDescription() -> String {
            let status = isSuccess ? "Success" : (errorMessage ?? "Failed")
            var lines = [test.title, "Result: \(status)"]
            if let details = technicalDetails {
                lines.append("Details: \(details)")
            }
            return lines.joined(separator: "\n")
        }
    }

    // MARK: - Dependencies

    private let stores: StoresManager
    private let connectivityObserver: ConnectivityObserver
    private let userNotificationCenter: UserNotificationsCenterAdapter
    private let pushNotesManager: PushNotesManager
    private let siteID: Int64
    private let siteURL: String?
    private let network: Network
    private let announcementsRemote: AnnouncementsRemote
    private let systemStatusRemote: SystemStatusRemote
    private let ordersRemote: OrdersRemote
    private let productsRemote: ProductsRemote
    private let pushNotificationEligibilityChecker: WooPushNotificationEligibilityChecking
    private let pluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol

    /// Active plugins from site status, cached after site test.
    ///
    private(set) var activeSystemPlugins: [SystemPlugin] = []

    /// Formatted system status report, cached after site test.
    ///
    private(set) var formattedSystemStatusReport: String?

    private var isJetpackPluginActive: Bool {
        activeSystemPlugins.contains { $0.plugin.hasPrefix("jetpack/") }
    }

    // MARK: - Initialization

    init(session: SessionManagerProtocol = ServiceLocator.stores.sessionManager,
         stores: StoresManager = ServiceLocator.stores,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver,
         userNotificationCenter: UserNotificationsCenterAdapter = UNUserNotificationCenter.current(),
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
         pushNotificationEligibilityChecker: WooPushNotificationEligibilityChecking = WooPushNotificationEligibilityCheck(),
         pluginVersionCheckerFactory: PluginVersionCheckerFactoryProtocol = PluginVersionCheckerFactory(),
         network: Network? = nil) {
        let network = network ?? AlamofireNetwork(credentials: session.defaultCredentials,
                                                   selectedSite: nil,
                                                   appPasswordSupportState: nil)
        self.network = network
        self.announcementsRemote = AnnouncementsRemote(network: network)
        self.systemStatusRemote = SystemStatusRemote(network: network)
        self.ordersRemote = OrdersRemote(network: network)
        self.productsRemote = ProductsRemote(network: network)
        self.stores = stores
        self.connectivityObserver = connectivityObserver
        self.userNotificationCenter = userNotificationCenter
        self.pushNotesManager = pushNotesManager
        self.pushNotificationEligibilityChecker = pushNotificationEligibilityChecker
        self.pluginVersionCheckerFactory = pluginVersionCheckerFactory
        self.siteID = session.defaultStoreID ?? .zero
        self.siteURL = session.defaultSite?.url
    }

    // MARK: - Running Tests

    /// Runs the specified tests sequentially and returns results.
    /// Stops at the first failure.
    ///
    func runTests(_ tests: [Test]) async -> [Result] {
        var results: [Result] = []

        for test in tests {
            let failure = await runTest(test)
            let result = failure.map { Result.failure(test: test, failure: $0) } ?? Result.success(test: test)
            results.append(result)

            if !result.isSuccess {
                break
            }
        }

        return results
    }

    /// Runs tests for a specific issue type.
    ///
    func runTests(for issue: SupportIssueType) async -> [Result] {
        guard let tests = issue.testsToRun else {
            return []
        }
        return await runTests(tests)
    }

    /// Runs a single test and returns failure details if the test failed, nil if successful.
    ///
    private func runTest(_ test: Test) async -> Failure? {
        switch test {
        case .internetConnection:
            return checkInternetConnection()
        case .wpComServers:
            return await checkWPComServers()
        case .site:
            return await checkSite()
        case .siteOrders:
            return await checkSiteOrders()
        case .loadingProducts:
            return await checkLoadingProducts()
        case .analyticsSetting:
            return await checkAnalyticsSetting()
        case .notifications:
            return await checkNotifications()
        }
    }

    // MARK: - Individual Checks (return nil on success, Failure on error)

    private func checkInternetConnection() -> Failure? {
        let status = connectivityObserver.currentStatus
        if case .reachable = status {
            DDLogInfo("SupportDiagnostics: ✅ Internet Connection")
            return nil
        }
        DDLogError("SupportDiagnostics: ❌ Internet Connection")
        return Failure(errorMessage: Localization.Error.noInternet)
    }

    private func checkWPComServers() async -> Failure? {
        await withCheckedContinuation { continuation in
            announcementsRemote.loadAnnouncements(appVersion: UserAgent.bundleShortVersion,
                                                   locale: Locale.current.identifier) { result in
                switch result {
                case .success:
                    DDLogInfo("SupportDiagnostics: ✅ WPCom connection")
                    continuation.resume(returning: nil)
                case .failure(let error):
                    DDLogError("SupportDiagnostics: ❌ WPCom connection\n\(error)")
                    continuation.resume(returning: Failure(errorMessage: Localization.Error.wpcomConnection,
                                                           technicalDetails: error.formattedTechnicalDetails))
                }
            }
        }
    }

    private func checkSite() async -> Failure? {
        await withCheckedContinuation { continuation in
            systemStatusRemote.fetchSystemStatusReport(for: siteID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let report):
                    DDLogInfo("SupportDiagnostics: ✅ Site connection")
                    self.activeSystemPlugins = report.activePlugins
                    self.formattedSystemStatusReport = SystemStatusReportViewModel.formatReport(with: report)
                    continuation.resume(returning: nil)
                case .failure(let error):
                    DDLogError("SupportDiagnostics: ❌ Site connection\n\(error)")
                    continuation.resume(returning: Failure(errorMessage: self.errorMessage(for: error),
                                                           technicalDetails: error.formattedTechnicalDetails))
                }
            }
        }
    }

    private func checkSiteOrders() async -> Failure? {
        do {
            _ = try await ordersRemote.loadAllOrders(for: siteID)
            DDLogInfo("SupportDiagnostics: ✅ Site Orders")
            return nil
        } catch {
            DDLogError("SupportDiagnostics: ❌ Site Orders\n\(error)")
            return Failure(errorMessage: errorMessage(for: error), technicalDetails: error.formattedTechnicalDetails)
        }
    }

    private func checkLoadingProducts() async -> Failure? {
        do {
            _ = try await productsRemote.loadAllProducts(for: siteID)
            DDLogInfo("SupportDiagnostics: ✅ Loading products")
            return nil
        } catch {
            DDLogError("SupportDiagnostics: ❌ Loading products\n\(error)")
            return Failure(errorMessage: errorMessage(for: error), technicalDetails: error.formattedTechnicalDetails)
        }
    }

    private func checkAnalyticsSetting() async -> Failure? {
        await withCheckedContinuation { continuation in
            let action = SettingAction.retrieveAnalyticsSetting(siteID: siteID) { result in
                switch result {
                case .success(let isEnabled):
                    if isEnabled {
                        DDLogInfo("SupportDiagnostics: ✅ Analytics enabled")
                        continuation.resume(returning: nil)
                    } else {
                        DDLogInfo("SupportDiagnostics: ⚠️ Analytics disabled")
                        continuation.resume(returning: Failure(errorMessage: Localization.Error.analyticsDisabled,
                                                               suggestedAction: .enableAnalytics))
                    }
                case .failure(let error):
                    DDLogError("SupportDiagnostics: ❌ Analytics check failed\n\(error)")
                    continuation.resume(returning: Failure(errorMessage: Localization.Error.analyticsCheckFailed,
                                                           technicalDetails: error.formattedTechnicalDetails))
                }
            }
            stores.dispatch(action)
        }
    }

    private func checkNotifications() async -> Failure? {
        // Sub-check 1: iOS notification permission
        let permissionResult = await checkNotificationPermission()
        if case .failure = permissionResult {
            DDLogInfo("SupportDiagnostics: ⚠️ Notifications not authorized")
            return Failure(errorMessage: Localization.Error.notificationsNotAuthorized,
                           suggestedAction: .openNotificationSettings)
        }

        let isEligibleForWooDrivenPushNotifications = await pushNotificationEligibilityChecker.checkEligibility()

        // Sub-check 2: if not eligible for Woo-driven PN
        if !isEligibleForWooDrivenPushNotifications {
            // Subcheck 2.1: does device have Jetpack?
            if !isJetpackPluginActive {
                DDLogError("SupportDiagnostics: ❌ Jetpack not active")
                return Failure(errorMessage: Localization.Error.jetpackNotActive, suggestedAction: .setupJetpack)
            } else if pushNotesManager.deviceID == nil { // Subcheck 2.2: registered with WPCom?
                DDLogError("SupportDiagnostics: ❌ device is not registered")
                return Failure(errorMessage: Localization.Error.deviceNotRegistered,
                               suggestedAction: .registerDevice)
            } else {
                // Sub-check 2.3: WPCom notification config
                let configResult = await checkNotificationConfig()
                switch configResult {
                case .success:
                    DDLogInfo("SupportDiagnostics: ✅ Notification settings configured")
                    return nil
                case .failure(let configError):
                    DDLogInfo("SupportDiagnostics: ⚠️ Notification config issue: \(configError)")
                    switch configError {
                    case .deviceNotRegistered:
                        return Failure(errorMessage: Localization.Error.deviceNotRegistered,
                                       suggestedAction: .registerDevice)
                    case .orderNotificationsDisabled(let settings):
                        return Failure(errorMessage: Localization.Error.orderNotificationsDisabled,
                                       suggestedAction: .enableOrderNotifications(settings: settings))
                    case .requestFailed(let error):
                        return Failure(errorMessage: Localization.Error.notificationConfigCheckFailed,
                                       technicalDetails: error.formattedTechnicalDetails)
                    }
                }
            }
        }

        // Sub-check 3: Self-driven push notifications
        if pushNotesManager.siteIDsRegisteredForWooPNs.contains(siteID) {
            DDLogInfo("SupportDiagnostics: ✅ Site registered for self-driven push notifications")
            return nil
        } else {
            do {
                let minimumVersion = WooPluginRequirements.minimumVersion
                let pluginVersionChecker = pluginVersionCheckerFactory.makeChecker(
                    siteID: siteID,
                    pluginPath: WooPluginRequirements.pluginPath,
                    minimumVersion: minimumVersion
                )
                let result = try await pluginVersionChecker.checkCompatibility()
                if case .incompatible(let currentVersion, _) = result {
                    DDLogError("SupportDiagnostics: ❌ Unable to register self-driven push token: " +
                               "WooCommerce plugin version \(currentVersion) is below required \(minimumVersion)")
                    return notificationFailure(
                        for: .wooCommercePluginUpdateRequired(currentVersion: currentVersion, requiredVersion: minimumVersion)
                    )
                } else {
                    DDLogError("SupportDiagnostics: ❌ device is not registered")
                    return Failure(errorMessage: Localization.Error.deviceNotRegistered,
                                   suggestedAction: .registerDevice)
                }
            } catch {
                DDLogError("SupportDiagnostics: ❌ device is not registered")
                return Failure(errorMessage: Localization.Error.deviceNotRegistered,
                               suggestedAction: .registerDevice)
            }
        }
    }

    private func notificationFailure(for error: NotificationRegistrationError) -> Failure {
        switch error {
        case .wooCommercePluginUpdateRequired(_, let requiredVersion):
            return Failure(errorMessage: Localization.Error.wooCommercePluginUpdateRequired(requiredVersion: requiredVersion),
                           suggestedAction: .updateWooCommercePlugin)
        }
    }

    private func checkNotificationPermission() async -> Swift.Result<Void, NotificationPermissionError> {
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

    private func checkNotificationConfig() async -> Swift.Result<Void, NotificationConfigError> {
        guard let deviceID = pushNotesManager.deviceID,
              let numericDeviceID = Int64(deviceID) else {
            return .failure(.deviceNotRegistered)
        }

        let currentSiteID = siteID

        return await withCheckedContinuation { continuation in
            let action = AccountAction.loadNotificationSettings(deviceID: numericDeviceID) { result in
                switch result {
                case .success(let settings):
                    guard let blog = settings.blogs.first(where: { $0.blogID == currentSiteID }),
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

    // MARK: - Fix Actions

    /// Enables WooCommerce Analytics on the site.
    ///
    func enableAnalytics() async throws {
        try await withCheckedThrowingContinuation { continuation in
            enableAnalyticsWithRetry(retries: 0) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func enableAnalyticsWithRetry(retries: Int, completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        let action = SettingAction.enableAnalyticsSetting(siteID: siteID) { [weak self] result in
            switch result {
            case .success:
                DDLogInfo("SupportDiagnostics: ✅ Analytics enabled successfully")
                completion(.success(()))
            case .failure(let error):
                if retries < 1 {
                    self?.enableAnalyticsWithRetry(retries: retries + 1, completion: completion)
                } else {
                    DDLogError("SupportDiagnostics: ❌ Failed to enable analytics\n\(error)")
                    completion(.failure(error))
                }
            }
        }
        stores.dispatch(action)
    }

    /// Registers the device for push notifications.
    ///
    func registerDevice() async throws {
        _ = try await pushNotesManager.registerDeviceAndWaitForTokenAcceptance()
        DDLogInfo("SupportDiagnostics: ✅ Device registered for push notifications")
    }

    /// Enables order notifications for the current site.
    ///
    func enableOrderNotifications(settings: NotificationSettings) async throws {
        guard let deviceID = pushNotesManager.deviceID,
              let numericDeviceID = Int64(deviceID) else {
            throw NotificationConfigError.deviceNotRegistered
        }

        let updatedBlogs: [NotificationSettings.Blog] = settings.blogs.map { blog in
            guard blog.blogID == siteID else { return blog }
            let updatedDevices: [NotificationSettings.Device] = blog.devices.map { device in
                guard device.deviceID == numericDeviceID else { return device }
                return device.copy(storeOrder: true)
            }
            return blog.copy(devices: updatedDevices)
        }
        let updatedSettings = settings.copy(blogs: updatedBlogs)

        try await withCheckedThrowingContinuation { continuation in
            let action = AccountAction.updateNotificationSettings(notificationSettings: updatedSettings) { result in
                switch result {
                case .success:
                    DDLogInfo("SupportDiagnostics: ✅ Order notifications enabled successfully")
                    continuation.resume()
                case .failure(let error):
                    DDLogError("SupportDiagnostics: ❌ Failed to enable order notifications\n\(error)")
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }

    /// Opens the device notification settings.
    ///
    func openNotificationSettings() -> URL? {
        URL(string: UIApplication.openNotificationSettingsURLString)
    }

    // MARK: - Error Helpers

    private func errorMessage(for error: Error) -> String {
        if error.isTimeoutError {
            return Localization.Error.timeout
        }
        if case DotcomError.jetpackNotConnected = error {
            return Localization.Error.noJetpackConnection
        }
        if error is DecodingError {
            return Localization.Error.decodingError
        }
        return Localization.Error.generic
    }

    // MARK: - Error Types

    enum NotificationPermissionError: Error {
        case notAuthorized(status: UNAuthorizationStatus)
    }

    enum NotificationConfigError: Error {
        case deviceNotRegistered
        case orderNotificationsDisabled(settings: NotificationSettings)
        case requestFailed(Error)
    }

    enum NotificationRegistrationError: Error, Equatable {
        case wooCommercePluginUpdateRequired(currentVersion: String, requiredVersion: String)
    }
}

extension SupportDiagnosticsService: SupportDiagnosticsServicing {}

// MARK: - Generating Context

extension SupportDiagnosticsService {
    /// Generates troubleshooting context from diagnostic results for the chat.
    ///
    static func troubleshootingDescription(from results: [Result]) -> String? {
        guard !results.isEmpty else { return nil }

        return results.enumerated().map { index, result in
            "## \(index + 1). " + result.troubleshootingDescription()
        }.joined(separator: "\n\n")
    }
}

// MARK: - Localization

private extension SupportDiagnosticsService {
    enum Localization {
        enum Test {
            static let internetConnection = NSLocalizedString(
                "supportDiagnosticsService.test.internetConnection",
                value: "Internet Connection",
                comment: "Title for the internet connection diagnostic test"
            )
            static let wpComServers = NSLocalizedString(
                "supportDiagnosticsService.test.wpComServers",
                value: "Connecting to WordPress.com Servers",
                comment: "Title for the WPCom servers diagnostic test"
            )
            static let site = NSLocalizedString(
                "supportDiagnosticsService.test.site",
                value: "Connecting to your site",
                comment: "Title for the site connection diagnostic test"
            )
            static let siteOrders = NSLocalizedString(
                "supportDiagnosticsService.test.siteOrders",
                value: "Fetching your site orders",
                comment: "Title for the site orders diagnostic test"
            )
            static let loadingProducts = NSLocalizedString(
                "supportDiagnosticsService.test.loadingProducts",
                value: "Fetching products in your store",
                comment: "Title for the loading products diagnostic test"
            )
            static let analyticsSetting = NSLocalizedString(
                "supportDiagnosticsService.test.analyticsSetting",
                value: "Checking analytics setting",
                comment: "Title for the analytics setting diagnostic test"
            )
            static let notifications = NSLocalizedString(
                "supportDiagnosticsService.test.notifications",
                value: "Checking notification settings",
                comment: "Title for the notification settings diagnostic test"
            )
        }

        enum Action {
            static let enableAnalytics = NSLocalizedString(
                "supportDiagnosticsService.action.enableAnalytics",
                value: "Enable Analytics",
                comment: "Action button to enable WooCommerce Analytics"
            )
            static let registerDevice = NSLocalizedString(
                "supportDiagnosticsService.action.registerDevice",
                value: "Register Device",
                comment: "Action button to register the device for push notifications"
            )
            static let enableOrderNotifications = NSLocalizedString(
                "supportDiagnosticsService.action.enableOrderNotifications",
                value: "Enable Order Notifications",
                comment: "Action button to enable order notifications"
            )
            static let setupJetpack = NSLocalizedString(
                "supportDiagnosticsService.action.setupJetpack",
                value: "Setup Jetpack",
                comment: "Action button to start the Jetpack setup flow"
            )
            static let updateWooCommercePlugin = NSLocalizedString(
                "supportDiagnosticsService.action.updateWooCommercePlugin",
                value: "Update WooCommerce",
                comment: "Action button to update the WooCommerce plugin"
            )
            static let openSettings = NSLocalizedString(
                "supportDiagnosticsService.action.openSettings",
                value: "Open Settings",
                comment: "Action button to open device notification settings"
            )
            static let retryDiagnostics = NSLocalizedString(
                "supportDiagnosticsService.action.retryDiagnostics",
                value: "Retry",
                comment: "Action button to retry diagnostic tests"
            )
        }

        enum Error {
            static let noInternet = NSLocalizedString(
                "supportDiagnosticsService.error.noInternet",
                value: "It looks like you're not connected to the internet.\n\n" +
                "Ensure your Wi-Fi is turned on. If you're using mobile data, make sure it's enabled in your device settings.",
                comment: "Message when there is no internet connection"
            )
            static let wpcomConnection = NSLocalizedString(
                "supportDiagnosticsService.error.wpcomConnection",
                value: "We can't connect to WordPress.com right now.\n\n" +
                "Try again in a few minutes.",
                comment: "Message when we can't reach WPCom"
            )
            static let timeout = NSLocalizedString(
                "supportDiagnosticsService.error.timeout",
                value: "Your site is taking too long to respond.\n\n" +
                "Please contact your hosting provider for further assistance.",
                comment: "Message when there is a timeout error"
            )
            static let decodingError = NSLocalizedString(
                "supportDiagnosticsService.error.decodingError",
                value: "We can't work properly with your site's response.",
                comment: "Message when there is a decoding error"
            )
            static let noJetpackConnection = NSLocalizedString(
                "supportDiagnosticsService.error.noJetpackConnection",
                value: "There is a problem with your Jetpack connection.",
                comment: "Message when there is a Jetpack connection error"
            )
            static let generic = NSLocalizedString(
                "supportDiagnosticsService.error.generic",
                value: "There seems to be a problem with your site.\n\n" +
                "Please contact your hosting provider for further assistance.",
                comment: "Message when there is a generic error"
            )
            static let analyticsDisabled = NSLocalizedString(
                "supportDiagnosticsService.error.analyticsDisabled",
                value: "WooCommerce Analytics is not enabled on your store.\n\n" +
                "Analytics data like revenue and order stats won't be available until it's enabled.",
                comment: "Message when WooCommerce Analytics is disabled"
            )
            static let analyticsCheckFailed = NSLocalizedString(
                "supportDiagnosticsService.error.analyticsCheckFailed",
                value: "We couldn't check your analytics setting.",
                comment: "Message when the analytics setting check fails"
            )
            static let jetpackNotActive = NSLocalizedString(
                "supportDiagnosticsService.error.jetpackNotActive",
                value: "The Jetpack plugin doesn't appear to be active on your site.\n\n" +
                "Push notifications require an active Jetpack connection.",
                comment: "Message when Jetpack plugin is not active"
            )
            static let notificationsNotAuthorized = NSLocalizedString(
                "supportDiagnosticsService.error.notificationsNotAuthorized",
                value: "Push notifications are not allowed for this app.\n\n" +
                "Enable them in your device Settings to receive order notifications.",
                comment: "Message when iOS notification permission is denied"
            )
            static let deviceNotRegistered = NSLocalizedString(
                "supportDiagnosticsService.error.deviceNotRegistered",
                value: "Your device doesn't appear to be registered for push notifications.",
                comment: "Message when the device is not registered for push notifications"
            )
            static func wooCommercePluginUpdateRequired(requiredVersion: String) -> String {
                let format = NSLocalizedString(
                    "supportDiagnosticsService.error.wooCommercePluginUpdateRequired",
                    value: "Your WooCommerce plugin needs to be updated to enable push notifications.\n\n" +
                    "Update WooCommerce to version %1$@ or newer, then try registering again.",
                    comment: "Message when WooCommerce plugin must be updated for push notifications. " +
                    "%1$@ is the required WooCommerce plugin version."
                )
                return String.localizedStringWithFormat(format, requiredVersion)
            }
            static let orderNotificationsDisabled = NSLocalizedString(
                "supportDiagnosticsService.error.orderNotificationsDisabled",
                value: "Order notifications are not enabled for this store.\n\n" +
                "Enable them to receive alerts when new orders come in.",
                comment: "Message when order notifications are disabled"
            )
            static let notificationConfigCheckFailed = NSLocalizedString(
                "supportDiagnosticsService.error.notificationConfigCheckFailed",
                value: "We couldn't check your notification settings.",
                comment: "Message when the notification config check fails"
            )
        }
    }
}
