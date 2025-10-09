import UIKit
import Combine
import Storage
import class Networking.UserAgent
import Experiments
import class WidgetKit.WidgetCenter
import protocol WooFoundation.Analytics
import protocol Yosemite.StoresManager
import struct Yosemite.Site

import CocoaLumberjackSwift
import KeychainAccess
import WordPressUI
import WordPressAuthenticator
import AutomatticTracks

import class Yosemite.ScreenshotStoresManager

// In that way, Inject will be available in the entire target.
@_exported import Inject

import WormholySwift

// MARK: - Woo's App Delegate!
//
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// AppDelegate's Instance
    ///
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    /// Tab Bar Controller
    ///
    var tabBarController: MainTabBarController? {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .compactMap({ $0.delegate as? SceneDelegate })
            .first else { return nil }
        return sceneDelegate.tabBarController
    }

    /// Coordinates the Jetpack setup flow for users authenticated without Jetpack.
    ///
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?

    private var universalLinkRouter: UniversalLinkRouter?

    private(set) var requirementsChecker = RequirementsChecker(baseViewController: nil)

    /// Handles events to background refresh the app.
    ///
    let appRefreshHandler = BackgroundTaskRefreshDispatcher()

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: - AppDelegate Methods

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setup Components
        setupStartupWaitingTimeTracker()

        let stores = ServiceLocator.stores
        let analytics = ServiceLocator.analytics
        let pushNotesManager = ServiceLocator.pushNotesManager
        stores.initializeAfterDependenciesAreInitialized()
        setupAnalytics(analytics)

        setupCocoaLumberjack()
        setupLibraryLogger()
        setupLogLevel(.verbose)
        setupPushNotificationsManagerIfPossible(pushNotesManager, stores: stores)
        setupAppRatingManager()
        setupWormholy()
        setupKeyboardStateProvider()
        handleLaunchArguments()
        setupUserNotificationCenter()

        // Components that require prior Auth
        setupZendesk()

        // Yosemite Initialization
        synchronizeEntitiesIfPossible()
        listenToAuthenticationFailureNotifications()

        // Since we are using Injection for refreshing the content of the app in debug mode,
        // we are going to enable Inject.animation that will be used when
        // ever new source code is injected into our application.
        Inject.animation = .interactiveSpring()

        // Upgrade check...
        // This has to be called after A/B testing setup in `setupAnalytics` (which calls
        // `WooAnalytics.refreshUserData`) if any of the Tracks events in `checkForUpgrades` is
        // used as an exposure event for an experiment.
        // For example, `application_installed` could be the exposure event for logged-out experiments.
        checkForUpgrades()

        // Cache onboarding state to speed IPP process
        refreshCardPresentPaymentsOnboardingIfNeeded(completion: reconnectToTapToPayReaderIfNeeded)

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Global UIAppearance that doesn't require a WindowScene
        setupComponentsAppearance()
        disableAnimationsIfNeeded()

        // Don't track startup waiting time if user starts logged out
        if !ServiceLocator.stores.isAuthenticated {
            cancelStartupWaitingTimeTracker()
        }

        // Register for background app refresh events (scene will schedule actual refreshes)
        appRefreshHandler.registerSystemTaskIdentifier()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .compactMap({ $0.delegate as? SceneDelegate })
            .first,
              let rootViewController = sceneDelegate.window?.rootViewController else {
            fatalError()
        }

        if let universalLinkRouter = sceneDelegate.universalLinkRouter, universalLinkRouter.canHandle(url: url) {
            universalLinkRouter.handle(url: url)
            return true
        }

        return handleAuthenticationUrl(url, options: options, rootViewController: rootViewController)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let defaultStoreID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        ServiceLocator.pushNotesManager.registerDeviceToken(with: deviceToken, defaultStoreID: defaultStoreID)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ServiceLocator.pushNotesManager.registrationDidFail(with: error)
    }

    /// Called when the app receives a remote notification in the background.
    /// For local/remote notification tap events, please refer to `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:)`.
    /// When receiving a local/remote notification in the foreground, please refer to
    /// `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:)`.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        await ServiceLocator.pushNotesManager.handleRemoteNotificationInTheBackground(userInfo: userInfo)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Simulate push notification for capturing snapshot.
        // This is supposed to be called only by the WooCommerceScreenshots target.
        if ProcessConfiguration.shouldSimulatePushNotification {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString(
                "You have a new order! 🎉",
                comment: "Title for the mocked order notification needed for the AppStore listing screenshot"
            )
            content.body = NSLocalizedString(
                "New order for $13.98 on Your WooCommerce Store",
                comment: "Message for the mocked order notification needed for the AppStore listing screenshot. " +
                "'Your WooCommerce Store' is the name of the mocked store."
            )

            // show this notification seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            // add our notification request
            UNUserNotificationCenter.current().add(request)
        }
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let quickAction = QuickAction(rawValue: shortcutItem.type),
            let tabBarController else {
            completionHandler(false)
            return
        }
        switch quickAction {
        case QuickAction.addProduct:
            MainTabBarController.presentAddProductFlow()
            completionHandler(true)
        case QuickAction.addOrder:
            tabBarController.navigate(to: OrdersDestination.createOrder)
            completionHandler(true)
        case QuickAction.openOrders:
            tabBarController.navigate(to: OrdersDestination.orderList)
            completionHandler(true)
        case QuickAction.collectPayment:
            tabBarController.navigate(to: OrdersDestination.createOrder)
            completionHandler(true)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        cancelStartupWaitingTimeTracker()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Handled per-scene in SceneDelegate.sceneWillEnterForeground(_:)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.

        requirementsChecker.checkEligibilityForDefaultStore()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DDLogVerbose("👀 Application terminating...")
        NotificationCenter.default.post(name: .applicationTerminating, object: nil)
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let sceneDelegate = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .compactMap({ $0.delegate as? SceneDelegate })
                .first {
                sceneDelegate.handleWebActivity(userActivity)
            }
        }

        SpotlightManager.handleUserActivity(userActivity)
        trackWidgetTappedIfNeeded(userActivity: userActivity)

        return true
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        let size = os_proc_available_memory()
        DDLogDebug("Received memory warning: Available memory - \(size)")
        ServiceLocator.imageService.clearMemoryCache()
    }
}

// MARK: - UIScene Configuration
extension AppDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Resources tied to discarded scenes can be released here if needed.
    }
}

// MARK: - Initialization Methods
//
extension AppDelegate {

    /// Sets up all of the component(s) Appearance.
    ///
    func setupComponentsAppearance() {
        setupWooAppearance()
        setupFancyAlertAppearance()
        setupFancyButtonAppearance()
    }

    /// Sets up WooCommerce's UIAppearance.
    ///
    func setupWooAppearance() {
        UINavigationBar.applyWooAppearance()
        UILabel.applyWooAppearance()
        UITabBar.applyWooAppearance()

        // Apply tint to current key window when available
        if let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            keyWindow.tintColor = .primary
        }
    }

    /// Sets up FancyAlert's UIAppearance.
    ///
    func setupFancyAlertAppearance() {
        let appearance = FancyAlertView.appearance()
        appearance.bodyBackgroundColor = .systemColor(.systemBackground)
        appearance.bottomBackgroundColor = appearance.bodyBackgroundColor
        appearance.bottomDividerColor = .listSmallIcon
        appearance.topDividerColor = appearance.bodyBackgroundColor

        appearance.titleTextColor = .text
        appearance.titleFont = UIFont.title2SemiBold

        appearance.bodyTextColor = .text
        appearance.bodyFont = UIFont.body

        appearance.actionFont = UIFont.headline
        appearance.infoFont = UIFont.subheadline
        appearance.infoTintColor = .accent
        appearance.headerBackgroundColor = .alertHeaderImageBackgroundColor
    }

    /// Sets up FancyButton's UIAppearance.
    ///
    func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.primaryNormalBackgroundColor = .primaryButtonBackground
        appearance.primaryNormalBorderColor = .primaryButtonBorder
        appearance.primaryHighlightBackgroundColor = .primaryButtonDownBackground
        appearance.primaryHighlightBorderColor = .primaryButtonDownBorder
    }

    /// Sets up the Zendesk SDK.
    ///
    func setupZendesk() {
        ZendeskProvider.shared.initialize()
    }

    /// Sets up the WordPress Authenticator.
    ///
    func setupAnalytics(_ analytics: Analytics) {
        analytics.initialize()
    }

    /// Sets up CocoaLumberjack logging.
    ///
    func setupCocoaLumberjack() {
        var fileLogger = ServiceLocator.fileLogger
        fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7

        guard let logger = fileLogger as? DDFileLogger else {
            return
        }
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(logger)
    }

    /// Sets up loggers for WordPress libraries
    ///
    func setupLibraryLogger() {
        let logger = ServiceLocator.wordPressLibraryLogger
        WPSharedSetLoggingDelegate(logger)
        WPAuthenticatorSetLoggingDelegate(logger)
    }

    /// Sets up the current Log Level.
    ///
    func setupLogLevel(_ level: DDLogLevel) {
        CocoaLumberjackSwift.dynamicLogLevel = level
    }

    /// Push Notifications: Authorization + Registration!
    ///
    func setupPushNotificationsManagerIfPossible(_ pushNotesManager: PushNotesManager, stores: StoresManager) {
        #if targetEnvironment(simulator)
            DDLogVerbose("👀 Push Notifications are not supported in the Simulator!")
        #else
            let pushNotesManager = ServiceLocator.pushNotesManager
            pushNotesManager.registerForRemoteNotifications()
            pushNotesManager.ensureAuthorizationIsRequested(includesProvisionalAuth: false, onCompletion: nil)
        #endif
    }

    func setupUserNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Set up app review prompt
    ///
    func setupAppRatingManager() {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            DDLogError("No CFBundleShortVersionString found in Info.plist")
            return
        }

        let appRating = AppRatingManager.shared
        appRating.register(section: "notifications", significantEventCount: WooConstants.notificationEventCount)
        appRating.systemWideSignificantEventCountRequiredForPrompt = WooConstants.systemEventCount
        appRating.setVersion(version)
    }

    /// Set up Wormholy only in Debug build configuration
    ///
    func setupWormholy() {
        // We want to activate it programmatically, not using the shake.
        Wormholy.shakeEnabled = false
    }

    /// Set up `KeyboardStateProvider`
    ///
    func setupKeyboardStateProvider() {
        // Simply _accessing_ it is enough. We only want the object to be initialized right away
        // so it can start observing keyboard changes.
        _ = ServiceLocator.keyboardStateProvider
    }

    /// Set up the app startup waiting time tracker
    ///
    func setupStartupWaitingTimeTracker() {
        // Simply _accessing_ it is enough. We only want the object to be initialized right away
        // so it can start tracking the waiting time.
        _ = ServiceLocator.startupWaitingTimeTracker
    }

    /// Cancel the app startup waiting time tracker
    ///
    func cancelStartupWaitingTimeTracker() {
        ServiceLocator.startupWaitingTimeTracker.endWithoutTracking()
    }

    func handleLaunchArguments() {
        if ProcessConfiguration.shouldLogoutAtLaunch {
            ServiceLocator.stores.deauthenticate()
        }

        if ProcessConfiguration.shouldUseScreenshotsNetworkLayer {
            ServiceLocator.setStores(ScreenshotStoresManager(storageManager: ServiceLocator.storageManager))
        }

        if ProcessConfiguration.shouldSimulatePushNotification {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
        }
    }

    func disableAnimationsIfNeeded() {
        guard ProcessConfiguration.shouldDisableAnimations else {
            return
        }

        UIView.setAnimationsEnabled(false)

        /// Trick found at: https://twitter.com/twannl/status/1232966604142653446
        UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .forEach {
                $0.layer.speed = 100
            }
    }

    func refreshCardPresentPaymentsOnboardingIfNeeded(completion: @escaping (() -> Void)) {
        ServiceLocator.cardPresentPaymentsOnboardingIPPUsersRefresher.refreshIPPUsersOnboardingState(completion: completion)
    }

    func reconnectToTapToPayReaderIfNeeded() {
        ServiceLocator.tapToPayReconnectionController.reconnectIfNeeded()
    }

    /// Tracks if the application was opened via a widget tap.
    ///
    func trackWidgetTappedIfNeeded(userActivity: NSUserActivity) {
        switch userActivity.activityType {
        case WooConstants.storeInfoWidgetKind:
            let widgetFamily = userActivity.userInfo?[WidgetCenter.UserInfoKey.family] as? String
            ServiceLocator.analytics.track(event: .Widgets.widgetTapped(name: .todayStats, family: widgetFamily))
        case WooConstants.appLinkWidgetKind:
            ServiceLocator.analytics.track(event: .Widgets.widgetTapped(name: .appLink))
        default:
            break
        }
    }
}


// MARK: - Minimum Version
//
private extension AppDelegate {

    func checkForUpgrades() {
        let currentVersion = UserAgent.bundleShortVersion
        let versionOfLastRun = UserDefaults.standard[.versionOfLastRun] as? String
        if versionOfLastRun == nil {
            // First run after a fresh install
            ServiceLocator.analytics.track(.applicationInstalled,
                                           withProperties: ["after_abtest_setup": true])
            UserDefaults.standard[.installationDate] = Date()
        } else if versionOfLastRun != currentVersion {
            // App was upgraded
            ServiceLocator.analytics.track(.applicationUpgraded, withProperties: ["previous_version": versionOfLastRun ?? String()])
        }

        UserDefaults.standard[.versionOfLastRun] = currentVersion
    }
}


// MARK: - Authentication Methods
//
extension AppDelegate {
    /// Whenever we're in an Authenticated state, let's Sync all of the WC-Y entities.
    ///
    private func synchronizeEntitiesIfPossible() {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }

        ServiceLocator.stores.synchronizeEntities(onCompletion: nil)
    }

    /// De-authenticates the user upon application password generation failure or WPCOM token expiry.
    ///
    private func listenToAuthenticationFailureNotifications() {
        let stores = ServiceLocator.stores
        if stores.isAuthenticatedWithoutWPCom {
            stores.listenToApplicationPasswordGenerationFailureNotification()
        } else {
            stores.listenToWPCOMInvalidWPCOMTokenNotification()
        }
    }

    /// Runs whenever the Authentication Flow is completed successfully.
    ///
    func authenticatorWasDismissed() {
        setupPushNotificationsManagerIfPossible(ServiceLocator.pushNotesManager, stores: ServiceLocator.stores)
        requirementsChecker.checkEligibilityForDefaultStore()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await ServiceLocator.pushNotesManager.handleUserResponseToNotification(response)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await ServiceLocator.pushNotesManager.handleNotificationInTheForeground(notification)
    }
}

// MARK: - Magic link
extension AppDelegate {
    func handleAuthenticationUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any], rootViewController: UIViewController) -> Bool {
        return if ServiceLocator.stores.isAuthenticated {
            handleAuthenticationUrlForJetpackSetup(url, rootViewController: rootViewController)
        } else {
            ServiceLocator.authenticationManager.handleAuthenticationUrl(url, options: options, rootViewController: rootViewController)
        }
    }

    func handleAuthenticationUrlForJetpackSetup(_ url: URL, rootViewController: UIViewController) -> Bool {
        if let site = ServiceLocator.stores.sessionManager.defaultSite {
            return handleAuthenticationUrlForJetpackSetup(with: site, url: url, rootViewController: rootViewController)
        } else {
            // Wait for the site to be available before handling the magic link
            ServiceLocator.stores.sessionManager.defaultSitePublisher
                .timeout(.seconds(30), scheduler: DispatchQueue.main)
                .first(where: { $0 != nil })
                .sink { [weak self] site in
                    guard let site else {
                        // This should never happen as we filter out nil values
                        return
                    }
                    _ = self?.handleAuthenticationUrlForJetpackSetup(with: site, url: url, rootViewController: rootViewController)
                }
                .store(in: &subscriptions)

            // Assume that we will handle the URL
            return true
        }
    }

    func handleAuthenticationUrlForJetpackSetup(with site: Site, url: URL, rootViewController: UIViewController) -> Bool {
        let coordinator = JetpackSetupCoordinator(site: site, rootViewController: rootViewController)
        jetpackSetupCoordinator = coordinator
        return coordinator.handleAuthenticationUrl(url)
    }
}

// MARK: - Home Screen Quick Actions

enum QuickAction: String {
    case addProduct = "AddProductAction"
    case addOrder = "AddOrderAction"
    case openOrders = "OpenOrdersAction"
    case collectPayment = "CollectPaymentAction"
}
