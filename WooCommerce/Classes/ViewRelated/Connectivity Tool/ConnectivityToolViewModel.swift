import Foundation
import Combine
import UIKit
import Yosemite
import enum Networking.DotcomError
import class Networking.AlamofireNetwork
import class Networking.AnnouncementsRemote
import class Networking.SystemStatusRemote
import class Networking.OrdersRemote
import class Networking.ProductsRemote
import class Networking.UserAgent
import enum Networking.SitePluginStatusEnum
import protocol WooFoundation.Analytics
import UserNotifications

final class ConnectivityToolViewModel {

    /// Cards to be rendered by the view.
    ///
    @Published var cards: [ConnectivityTool.Card] = []

    /// URL selected by an action button, to be opened in-app by the view layer.
    ///
    @Published var selectedURL: URL?

    /// Remote used to check the connection to WPCom servers.
    ///
    private let announcementsRemote: AnnouncementsRemote

    /// Remote used to check the connection to the site.
    ///
    private let systemStatusRemote: SystemStatusRemote

    /// Remote used to check the site orders.
    ///
    private let orderRemote: OrdersRemote

    /// Remote used to check loading products
    ///
    private let productsRemote: ProductsRemote

    /// Stores manager for dispatching Yosemite actions.
    ///
    private let stores: StoresManager

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    /// Adapter for checking notification authorization status.
    ///
    private let userNotificationCenter: UserNotificationsCenterAdapter

    /// WordPress.com device identifier for notification settings.
    ///
    private let deviceID: String?

    /// Credentials used for authenticating Jetpack connection requests.
    ///
    private let credentials: Credentials?

    /// The site URL used for authenticating Jetpack connection requests.
    ///
    private let siteURL: String?

    /// Site to be tested.
    ///
    private let siteID: Int64

    private var latestTestResult: [ConnectivityTestResult] = []

    private let network: AlamofireNetwork

    init(session: SessionManagerProtocol = ServiceLocator.stores.sessionManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         userNotificationCenter: UserNotificationsCenterAdapter = UNUserNotificationCenter.current(),
         deviceID: String? = ServiceLocator.pushNotesManager.deviceID) {

        let network = AlamofireNetwork(credentials: session.defaultCredentials, selectedSite: nil, appPasswordSupportState: nil)
        self.network = network
        self.announcementsRemote = AnnouncementsRemote(network: network)
        self.systemStatusRemote = SystemStatusRemote(network: network)
        self.orderRemote = OrdersRemote(network: network)
        self.productsRemote = ProductsRemote(network: network)
        self.stores = stores
        self.analytics = analytics
        self.userNotificationCenter = userNotificationCenter
        self.deviceID = deviceID
        self.credentials = session.defaultCredentials
        self.siteURL = session.defaultSite?.url
        self.siteID = session.defaultStoreID ?? .zero

        Task {
            await startConnectivityTest()
        }
    }

    /// Sequentially runs all connectivity tests defined in `ConnectivityTest`.
    /// Provide a `sinceTest` parameter to omit test cases before it..
    ///
    private func startConnectivityTest(sinceTest: ConnectivityTest = .internetConnection) async {
        let supportedTests: [ConnectivityTest] = {
            if stores.isAuthenticatedWithoutWPCom == false {
                [.internetConnection, .wpComServers, .site, .siteOrders, .loadingProducts, .analyticsSetting, .notifications]
            } else {
                [.internetConnection, .site, .siteOrders, .loadingProducts, .analyticsSetting]
            }
        }()

        let testsToRun = supportedTests.filter { $0.rawValue >= sinceTest.rawValue }
        for testCase in testsToRun {

            // Add an inProgress card for the current test.
            let cardIndex = cards.count
            cards.append(testCase.inProgressCard)

            // Start time snapshot
            let startTime = Date()

            // Run the test.
            let testResult = await runTest(for: testCase)

            // Time taken snapshot
            let timeTaken = Date().timeIntervalSince(startTime)

            // Update the test card with the test result.
            cards[cardIndex] = cards[cardIndex].updatingState(testResult)

            // Track test result
            trackResponseEvent(for: testCase, success: testResult.isSuccess, timeTaken: timeTaken)

            latestTestResult.append(ConnectivityTestResult(testCase: testCase,
                                                           result: testResult,
                                                           timeTaken: timeTaken))

            // Only continue with another test if the current test was successful.
            if !testResult.isSuccess {
                return // Exit connectivity test.
            }
        }

        // Add no connections issues card if all tests are successful.
        cards.append(noConnectionsIssueState())
    }

    /// This is not a user facing text but will be part of the Zendesk submission for troubleshooting.
    func troubleshootingDescription() -> String? {
        guard !latestTestResult.isEmpty else {
            return nil
        }

        return latestTestResult.enumerated().map { index, result in
            "## \(index + 1). " + result.description()
        }.joined()
    }

    /// Perform the test for a provided test case.
    ///
    private func runTest(for connectivityTest: ConnectivityTest) async -> ConnectivityToolCard.ConnectivityState {
        switch connectivityTest {
        case .internetConnection:
            return await testInternetConnectivity()
        case .wpComServers:
            return await testWPComServersConnectivity()
        case .site:
            return await testSiteConnectivity()
        case .siteOrders:
            return await testFetchingOrders()
        case .loadingProducts:
            return await testFetchingProducts()
        case .analyticsSetting:
            return await testAnalyticsSetting()
        case .notifications:
            return await testNotifications()
        }
    }

    /// Retries the last failed test case and the subsequent ones.
    ///
    private func retryTest(_ testCase: ConnectivityTest) {
        // Remove the last test result and card.
        if !latestTestResult.isEmpty {
            latestTestResult.removeLast()
        }
        if !cards.isEmpty {
            cards.removeLast()
        }

        // Run tests again from the failed one.
        Task {
            await startConnectivityTest(sinceTest: testCase)
        }
    }

    /// Perform internet connectivity case using the `connectivityObserver`.
    ///
    private func testInternetConnectivity() async -> ConnectivityToolCard.ConnectivityState {

        let status = ServiceLocator.connectivityObserver.currentStatus
        let reachable = {
            if case .reachable = status {
                DDLogInfo("Connectivity Tool: ✅ Internet Connection")
                return true
            } else {
                DDLogError("Connectivity Tool: ❌ Internet Connection")
                return false
            }
        }()

        let state: ConnectivityToolCard.ConnectivityState = reachable ?
            .success :
            .error(Localization.ErrorMessage.noInternet, [self.retryAction(for: .internetConnection)])

        return state
    }

    /// Test WPCom connectivity by fetching the mobile announcements.
    ///
    func testWPComServersConnectivity() async -> ConnectivityToolCard.ConnectivityState {
        await withCheckedContinuation { continuation in
            announcementsRemote.loadAnnouncements(appVersion: UserAgent.bundleShortVersion, locale: Locale.current.identifier) { result in

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ WPCom connection")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ WPCom connection\n\(error)")
                }

                let state: ConnectivityToolCard.ConnectivityState = result.isSuccess ?
                    .success :
                    .error(Localization.ErrorMessage.wpcomConnection, [self.retryAction(for: .wpComServers)])
                continuation.resume(returning: state
                )
            }
        }
    }

    /// Test Site connectivity by fetching the status report..
    ///
    func testSiteConnectivity() async -> ConnectivityToolCard.ConnectivityState {
        await withCheckedContinuation { continuation in
            systemStatusRemote.fetchSystemStatusReport(for: siteID) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success:
                    DDLogInfo("Connectivity Tool: ✅ Site connection")
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ Site connection\n\(error)")
                }

                let state = self.stateForSiteResult(result, operation: .site)
                continuation.resume(returning: state)
            }
        }
    }

    /// Test fetching the site orders by actually fetching orders.
    ///
    func testFetchingOrders() async -> ConnectivityToolCard.ConnectivityState {
        do {
            _ = try await orderRemote.loadAllOrders(for: siteID)
            DDLogInfo("Connectivity Tool: ✅ Site Orders")
            return stateForSiteResult(Result<[Order], Error>.success([]), operation: .siteOrders)
        } catch {
            DDLogError("Connectivity Tool: ❌ Site Orders\n\(error)")
            return stateForSiteResult(Result<[Order], Error>.failure(error), operation: .siteOrders)
        }
    }

    /// Test fetching products.
    ///
    func testFetchingProducts() async -> ConnectivityToolCard.ConnectivityState {
        do {
            _ = try await productsRemote.loadAllProducts(for: siteID)
            DDLogInfo("Connectivity Tool: ✅ Retrieving products successfully")
            return stateForSiteResult(Result<[Product], Error>.success([]), operation: .loadingProducts)
        } catch {
            DDLogError("Connectivity Tool: ❌ Failed to load products\n\(error)")
            return stateForSiteResult(Result<[Product], Error>.failure(error), operation: .loadingProducts)
        }
    }

    /// Test whether WooCommerce Analytics is enabled on the site.
    ///
    @MainActor
    func testAnalyticsSetting() async -> ConnectivityToolCard.ConnectivityState {
        await withCheckedContinuation { continuation in
            let action = SettingAction.retrieveAnalyticsSetting(siteID: siteID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let isEnabled):
                    if isEnabled {
                        DDLogInfo("Connectivity Tool: ✅ Analytics setting enabled")
                        continuation.resume(returning: .success)
                    } else {
                        DDLogInfo("Connectivity Tool: ⚠️ Analytics setting disabled")
                        let enableAction = ConnectivityToolCard.ConnectivityState.Action(
                            title: Localization.Action.enableAnalytics,
                            systemImage: SystemImages.enableAction.rawValue,
                            action: { [weak self] in
                                self?.enableAnalytics()
                            }
                        )
                        continuation.resume(returning: .error(Localization.ErrorMessage.analyticsDisabled,
                                                                    [enableAction, self.retryAction(for: .analyticsSetting)]))
                    }
                case .failure(let error):
                    DDLogError("Connectivity Tool: ❌ Analytics setting check failed\n\(error)")
                    let technicalDetails = String(describing: error)
                    let viewDetailsAction = ConnectivityToolCard.ConnectivityState.Action(
                        title: Localization.Action.viewDetails,
                        systemImage: SystemImages.viewDetails.rawValue,
                        technicalDetails: technicalDetails
                    )
                    continuation.resume(returning: .error(Localization.ErrorMessage.analyticsCheckFailed,
                                                                [viewDetailsAction, self.retryAction(for: .analyticsSetting)]))
                }
            }
            stores.dispatch(action)
        }
    }

    /// Enables WooCommerce Analytics on the site with one automatic retry (known API quirk).
    ///
    private func enableAnalytics(retries: Int = 0) {
        // Hide card content and show loading indicator while enabling.
        if let cardIndex = cards.lastIndex(where: { $0.testCase == .analyticsSetting }) {
            cards[cardIndex] = ConnectivityTest.analyticsSetting.inProgressCard
        }

        let action = SettingAction.enableAnalyticsSetting(siteID: siteID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                DDLogInfo("Connectivity Tool: ✅ Analytics enabled successfully")
                // Update the analytics setting card to show relaunch message.
                if let index = self.cards.lastIndex(where: { $0.testCase == .analyticsSetting }) {
                    self.cards[index] = ConnectivityTool.Card(
                        testCase: .analyticsSetting,
                        title: ConnectivityTest.analyticsSetting.title,
                        icon: ConnectivityTest.analyticsSetting.icon,
                        state: .empty(Localization.analyticsEnabledRelaunch)
                    )
                }
            case .failure(let error):
                if retries < 1 {
                    // Retry once due to known API quirk where first request fails.
                    self.enableAnalytics(retries: retries + 1)
                } else {
                    DDLogError("Connectivity Tool: ❌ Failed to enable analytics\n\(error)")
                    // Restore the error state with interactive buttons.
                    self.restoreAnalyticsCardActions()
                }
            }
        }
        stores.dispatch(action)
    }

    /// Restores the analytics setting card to its interactive error state after a failed enable attempt.
    ///
    private func restoreAnalyticsCardActions() {
        guard let index = cards.lastIndex(where: { $0.testCase == .analyticsSetting }) else {
            return
        }
        let enableAction = ConnectivityToolCard.ConnectivityState.Action(
            title: Localization.Action.enableAnalytics,
            systemImage: SystemImages.enableAction.rawValue,
            action: { [weak self] in
                self?.enableAnalytics()
            }
        )
        cards[index] = ConnectivityTool.Card(
            testCase: .analyticsSetting,
            title: ConnectivityTest.analyticsSetting.title,
            icon: ConnectivityTest.analyticsSetting.icon,
            state: .error(Localization.ErrorMessage.analyticsDisabled, [enableAction, retryAction(for: .analyticsSetting)])
        )
    }

    // MARK: - Notifications Check

    /// Test notification settings: Jetpack plugin status, iOS permission, and notification config.
    ///
    @MainActor
    func testNotifications() async -> ConnectivityToolCard.ConnectivityState {
        // Sub-check 1: Jetpack plugin is active.
        let jetpackResult = await checkJetpackPluginActiveIfNeeded()
        if case .failure(let error) = jetpackResult {
            DDLogError("Connectivity Tool: ❌ Jetpack plugin check failed\n\(error)")
            let readMoreAction = ConnectivityToolCard.ConnectivityState.Action(
                title: Localization.Action.readMore,
                systemImage: SystemImages.readMore.rawValue,
                action: { [weak self] in
                    self?.selectedURL = WooConstants.URLs.troubleshootJetpackConnection.asURL()
                    self?.analytics.track(event: .ConnectivityTool.readMoreTapped())
                }
            )
            return .error(Localization.ErrorMessage.jetpackPluginNotActive, [readMoreAction, retryAction(for: .notifications)])
        }

        // Sub-check 2: iOS notification permission is authorized.
        let permissionResult = await checkNotificationPermission()
        if case .failure = permissionResult {
            DDLogInfo("Connectivity Tool: ⚠️ Notifications not authorized")
            let openSettingsAction = ConnectivityToolCard.ConnectivityState.Action(
                title: Localization.Action.openSettings,
                systemImage: SystemImages.openSettings.rawValue,
                action: { [weak self] in
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        self?.selectedURL = url
                    }
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
                return .error(Localization.ErrorMessage.deviceNotRegistered, [retryAction(for: .notifications)])
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
            case .siteNotFound:
                return .error(Localization.ErrorMessage.notificationSiteNotFound, [retryAction(for: .notifications)])
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
    private func checkJetpackPluginActiveIfNeeded() async -> Result<Void, JetpackCheckError> {
        /// WPCom and CIAB sites have Jetpack by default so skip this check
        guard stores.sessionManager.defaultSite?.isWordPressComStore == false,
              stores.sessionManager.defaultSite?.isCIAB == false else {
            return .success(())
        }

        /// Authenticate the JetpackConnectionStore with WPCom credentials.
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
    private func checkNotificationPermission() async -> Result<Void, NotificationPermissionError> {
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
    private func checkNotificationConfig() async -> Result<Void, NotificationConfigError> {
        guard let deviceID, let numericDeviceID = Int64(deviceID) else {
            return .failure(.deviceNotRegistered)
        }

        return await withCheckedContinuation { continuation in
            let action = AccountAction.loadNotificationSettings(deviceID: numericDeviceID) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let settings):
                    guard let blog = settings.blogs.first(where: { $0.blogID == self.siteID }) else {
                        continuation.resume(returning: .failure(.siteNotFound))
                        return
                    }
                    guard let device = blog.devices.first(where: { $0.deviceID == numericDeviceID }) else {
                        continuation.resume(returning: .failure(.deviceNotRegistered))
                        return
                    }
                    if device.storeOrder {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(.orderNotificationsDisabled(settings: settings)))
                    }
                case .failure(let error):
                    continuation.resume(returning: .failure(.requestFailed(error)))
                }
            }
            stores.dispatch(action)
        }
    }

    /// Enables order notifications for the current site and device.
    ///
    private func enableOrderNotifications(settings: NotificationSettings) {
        guard let deviceID, let numericDeviceID = Int64(deviceID) else { return }

        // Show loading indicator while enabling.
        if let cardIndex = cards.lastIndex(where: { $0.testCase == .notifications }) {
            cards[cardIndex] = ConnectivityTest.notifications.inProgressCard
        }

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
                if let index = self.cards.lastIndex(where: { $0.testCase == .notifications }) {
                    self.cards[index] = ConnectivityTool.Card(
                        testCase: .notifications,
                        title: ConnectivityTest.notifications.title,
                        icon: ConnectivityTest.notifications.icon,
                        state: .success
                    )
                }
            case .failure(let error):
                DDLogError("Connectivity Tool: ❌ Failed to enable order notifications\n\(error)")
                self.restoreNotificationsCardActions(settings: settings)
            }
        }
        stores.dispatch(action)
    }

    /// Restores the notifications card to its interactive error state after a failed enable attempt.
    ///
    private func restoreNotificationsCardActions(settings: NotificationSettings) {
        guard let index = cards.lastIndex(where: { $0.testCase == .notifications }) else { return }
        let enableAction = ConnectivityToolCard.ConnectivityState.Action(
            title: Localization.Action.enableOrderNotifications,
            systemImage: SystemImages.enableAction.rawValue,
            action: { [weak self] in
                self?.enableOrderNotifications(settings: settings)
            }
        )
        cards[index] = ConnectivityTool.Card(
            testCase: .notifications,
            title: ConnectivityTest.notifications.title,
            icon: ConnectivityTest.notifications.icon,
            state: .error(Localization.ErrorMessage.orderNotificationsDisabled, [enableAction, retryAction(for: .notifications)])
        )
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
        case siteNotFound
        case requestFailed(Error)
    }

    private func stateForSiteResult<T>(_ result: Result<T, Error>, operation: ConnectivityTest) -> ConnectivityToolCard.ConnectivityState {
        guard case let .failure(error) = result else {
            return .success
        }

        let message: String
        let readMore = Localization.Action.readMore
        let generalTroubleshootAction = { [weak self] in
            self?.selectedURL = WooConstants.URLs.troubleshootErrorLoadingData.asURL()
            self?.analytics.track(event: .ConnectivityTool.readMoreTapped())
        }
        var readMoreAction = ConnectivityToolCard.ConnectivityState.Action(title: readMore,
                                                                           systemImage: SystemImages.readMore.rawValue,
                                                                           action: generalTroubleshootAction)
        let jetpackTroubleshootAction = { [weak self] in
            self?.selectedURL = WooConstants.URLs.troubleshootJetpackConnection.asURL()
            self?.analytics.track(event: .ConnectivityTool.readMoreTapped())
        }

        // Handle all types of errors but timeouts are specific.
        switch (error, error.isTimeoutError) {
        case (_, true):
            message = Localization.ErrorMessage.timeout
            return .error(message, [readMoreAction, retryAction(for: operation)])

        case (let decodingError as DecodingError, _):
            message = Localization.ErrorMessage.decodingError
            let technicalDetails = formatDecodingError(decodingError, operation: operation)
            let viewDetailsTitle = Localization.Action.viewDetails
            let viewDetailsAction = ConnectivityToolCard.ConnectivityState.Action(
                title: viewDetailsTitle,
                systemImage: SystemImages.viewDetails.rawValue,
                technicalDetails: technicalDetails
            )
            return .error(message, [viewDetailsAction, readMoreAction, retryAction(for: operation)])

        case (DotcomError.jetpackNotConnected, _):
            message = Localization.ErrorMessage.noJetpackConnection
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: jetpackTroubleshootAction)
            return .error(message, [readMoreAction, retryAction(for: operation)])

        case (let error, _):
            message = Localization.ErrorMessage.generic
            let technicalDetails = String(describing: error)
            let viewDetailsTitle = Localization.Action.viewDetails
            let viewDetailsAction = ConnectivityToolCard.ConnectivityState.Action(
                title: viewDetailsTitle,
                systemImage: SystemImages.viewDetails.rawValue,
                technicalDetails: technicalDetails
            )
            readMoreAction = .init(title: readMore, systemImage: SystemImages.readMore.rawValue, action: generalTroubleshootAction)
            return .error(message, [viewDetailsAction, readMoreAction, retryAction(for: operation)])
        }
    }

    private func retryAction(for testCase: ConnectivityTest) -> ConnectivityToolCard.ConnectivityState.Action {
        let retryText = Localization.Action.retry
        return .init(title: retryText, systemImage: SystemImages.retry.rawValue, action: { [weak self] in
            self?.retryTest(testCase)
        })
    }

    /// Tracks the event with the respective test response.
    ///
    private func trackResponseEvent(for test: ConnectivityToolViewModel.ConnectivityTest, success: Bool, timeTaken: Double) {
        let eventTest: WooAnalyticsEvent.ConnectivityTool.Test = {
            switch test {
            case .internetConnection: return .internet
            case .wpComServers: return .wpCom
            case .site: return .site
            case .siteOrders: return .orders
            case .loadingProducts: return .products
            case .analyticsSetting: return .analytics
            case .notifications: return .notifications
            }
        }()
        analytics.track(event: .ConnectivityTool.requestResponse(test: eventTest, success: success, timeTaken: timeTaken))
    }

    private func noConnectionsIssueState() -> ConnectivityTool.Card {
        .init(title: Localization.noIssues,
              icon: .empty,
              state: .empty(Localization.noIssuesMessage)
        )
    }

    /// Extracts detailed technical information from a DecodingError for debugging purposes.
    /// Contents are intentionally not localized for simplicity.
    ///
    private func formatDecodingError(_ error: DecodingError, operation: ConnectivityTest) -> String {
        var details: [String] = []

        details.append("Operation: \(operation.title)")
        details.append("Error Type: Decoding Error")
        details.append("")

        switch error {
        case .typeMismatch(let type, let context):
            details.append("Issue: Type Mismatch")
            details.append("Expected Type: \(type)")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        case .valueNotFound(let type, let context):
            details.append("Issue: Required Value Not Found")
            details.append("Expected Type: \(type)")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        case .keyNotFound(let key, let context):
            details.append("Issue: Required Key Not Found")
            details.append("Missing Key: \(key.stringValue)")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        case .dataCorrupted(let context):
            details.append("Issue: Data Corrupted")
            details.append("Coding Path: \(formatCodingPath(context.codingPath))")
            details.append("Description: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                details.append("Underlying Error: \(underlyingError.localizedDescription)")
            }

        @unknown default:
            details.append("Issue: Unknown Decoding Error")
            details.append("Description: \(error.localizedDescription)")
        }

        return details.joined(separator: "\n")
    }

    /// Formats a coding path into a readable string representation.
    ///
    private func formatCodingPath(_ codingPath: [CodingKey]) -> String {
        guard !codingPath.isEmpty else {
            return "Root level"
        }
        return codingPath.map { $0.stringValue }.joined(separator: " → ")
    }
}

fileprivate struct ConnectivityTestResult {
    let testCase: ConnectivityToolViewModel.ConnectivityTest
    let result: ConnectivityToolCard.ConnectivityState
    let timeTaken: TimeInterval

    /// This is not a user facing text, but will be part of the attachment sent to Zendesk
    func description() -> String {
        let lines: [String] = [
            caseName,
            "Took: \(formattedTimeTaken)",
            "Result: \(resultDescription)",
            ""
        ]
        return lines.joined(separator: "\n")
    }

    private var formattedTimeTaken: String {
        let milliseconds = timeTaken * 1000
        return String(format: "%.0fms", milliseconds)
    }

    /// This is not a user facing text, but will be part of the attachment sent to Zendesk
    private var caseName: String {
        switch testCase {
        case .internetConnection: "Internet Connection"
        case .wpComServers: "Connecting to WordPress.com Servers"
        case .site: "Connecting to your site"
        case .siteOrders: "Fetching your site orders"
        case .loadingProducts: "Fetching products in your store"
        case .analyticsSetting: "Checking analytics setting"
        case .notifications: "Checking notification settings"
        }
    }

    /// This is not a user facing text, but will be part of the attachment sent to Zendesk
    private var resultDescription: String {
        switch result {
        case .inProgress: return "In progress"
        case .success: return "Success"
        case .empty(let message): return message
        case .error(_, let actions):
            let lines = actions.compactMap { $0.technicalDetails }
            return lines.joined(separator: "\n")
        }
    }
}


private extension ConnectivityToolViewModel {
    enum Localization {
        static let noIssues = NSLocalizedString(
            "connectivityToolViewModel.message.noIssues",
            value: "No connection issues",
            comment: "Title for when there are no connection issues in the connectivity tool screen"
        )
        static let noIssuesMessage = NSLocalizedString(
            "connectivityToolViewModel.message.noIssuesMessage",
            value: "If your data still isn't loading, contact our support team for assistance.",
            comment: "Info message when there are no connection issues in the connectivity tool screen"
        )
        static let analyticsEnabledRelaunch = NSLocalizedString(
            "connectivityToolViewModel.message.analyticsEnabledRelaunch",
            value: "Analytics has been enabled. Please relaunch the app for analytics data to be available.",
            comment: "Message shown after successfully enabling analytics in the connectivity tool"
        )
        enum ErrorMessage {
            static let noInternet = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.noInternet",
                value: "It looks like you're not connected to the internet.\n\n" +
                "Ensure your Wi-Fi is turned on. If you're using mobile data, make sure it's enabled in your device settings.",
                comment: "Message when there is no internet connection in the recovery tool"
            )
            static let wpcomConnection = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.wpcomConnection",
                value: "We can’t connect to WordPress.com right now.\n\n" +
                "Try again in a few minutes, or contact our support team and we will happily assist you.",
                comment: "Message when we can't reach WPCom in the recovery tool"
            )
            static let timeout = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.timeout",
                value: "Your site is taking too long to respond.\n\nPlease contact your hosting provider for further assistance.",
                comment: "Message when we there is a timeout error in the recovery tool"
            )
            static let decodingError = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.decodingError",
                value: "We can't work properly with your site's response.\n\n" +
                "View technical details below or contact our support team and we will happily assist you.",
                comment: "Message when we there is a decoding error in the recovery tool"
            )
            static let noJetpackConnection = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.jetpackNotConnected",
                value: "There is problem with your jetpack connection.\n\n" +
                "Read more about it or contact our support team and we will happily assist you.",
                comment: "Message when we there is a jetpack error in the recovery tool"
            )
            static let generic = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.default",
                value: "There seems to be a problem with your site.\n\nPlease contact your hosting provider for further assistance.",
                comment: "Message when we there is a generic error in the recovery tool"
            )
            static let analyticsDisabled = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.analyticsDisabled",
                value: "WooCommerce Analytics is not enabled on your store.\n\n" +
                "Analytics data like revenue and order stats won't be available until it's enabled.",
                comment: "Message when WooCommerce Analytics is disabled in the connectivity tool"
            )
            static let analyticsCheckFailed = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.analyticsCheckFailed",
                value: "We couldn't check your analytics setting.\n\n" +
                "Contact our support team for further assistance.",
                comment: "Message when the analytics setting check fails in the connectivity tool"
            )
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
            static let notificationSiteNotFound = NSLocalizedString(
                "connectivityToolViewModel.errorMessage.notificationSiteNotFound",
                value: "Your store was not found in the notification settings.\n\n" +
                "Try logging out and back in to re-register.",
                comment: "Message when the site is not found in notification settings in the connectivity tool"
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
            static let retry = NSLocalizedString(
                "connectivityToolViewModel.action.retry",
                value: "Retry test",
                comment: "Retry test button in the connectivity tool screen"
            )
            static let enableAnalytics = NSLocalizedString(
                "connectivityToolViewModel.action.enableAnalytics",
                value: "Enable Analytics",
                comment: "Action button to enable WooCommerce Analytics in the connectivity tool"
            )
            static let openSettings = NSLocalizedString(
                "connectivityToolViewModel.action.openSettings",
                value: "Open Settings",
                comment: "Action button to open device notification settings in the connectivity tool"
            )
            static let enableOrderNotifications = NSLocalizedString(
                "connectivityToolViewModel.action.enableOrderNotifications",
                value: "Enable Order Notifications",
                comment: "Action button to enable order notifications in the connectivity tool"
            )
        }
    }
}

private extension ConnectivityToolViewModel {
    enum SystemImages: String {
        case retry = "arrow.clockwise"
        case readMore = "arrow.up.forward.app"
        case viewDetails = "info.circle"
        case enableAction = "checkmark.circle"
        case openSettings = "gear"
    }
}

extension ConnectivityToolViewModel {
    enum ConnectivityTest: Int {
        case internetConnection
        case wpComServers
        case site
        case siteOrders
        case loadingProducts
        case analyticsSetting
        case notifications

        var title: String {
            switch self {
            case .internetConnection:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.internetConnection",
                    value: "Internet Connection",
                    comment: "Title for the internet connection connectivity tool card"
                )
            case .wpComServers:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.wpComServers",
                    value: "Connecting to WordPress.com Servers",
                    comment: "Title for the WPCom servers connectivity tool card"
                )
            case .site:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.site",
                    value: "Connecting to your site",
                    comment: "Title for the Your Site connectivity tool card"
                )
            case .siteOrders:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.siteOrders",
                    value: "Fetching your site orders",
                    comment: "Title for the Your Site Orders connectivity tool card"
                )
            case .loadingProducts:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.loadingProducts",
                    value: "Fetching products in your store",
                    comment: "Title for the test to load products in connectivity tool"
                )
            case .analyticsSetting:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.analyticsSetting",
                    value: "Checking analytics setting",
                    comment: "Title for the analytics setting check in the connectivity tool"
                )
            case .notifications:
                NSLocalizedString(
                    "connectivityToolViewModel.connectivityTest.notifications",
                    value: "Checking notification settings",
                    comment: "Title for the notification settings check in the connectivity tool"
                )
            }
        }

        var icon: ConnectivityToolCard.Icon {
            switch self {
            case .internetConnection:
                    .system("wifi")
            case .wpComServers:
                    .system("server.rack")
            case .site:
                    .system("storefront")
            case .siteOrders:
                    .system("list.clipboard")
            case .loadingProducts:
                    .system("cart")
            case .analyticsSetting:
                    .system("chart.bar.xaxis")
            case .notifications:
                    .system("bell.badge")
            }
        }

        var inProgressCard: ConnectivityTool.Card {
            .init(testCase: self, title: title, icon: icon, state: .inProgress)
        }
    }
}

extension ConnectivityTool.Card {

    /// Updates a card state to a new given state.
    ///
    func updatingState(_ newState: ConnectivityToolCard.ConnectivityState) -> ConnectivityTool.Card {
        Self.init(testCase: testCase, title: title, icon: icon, state: newState)
    }
}
