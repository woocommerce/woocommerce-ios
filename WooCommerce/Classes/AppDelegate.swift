import UIKit
import CoreData
import Storage
import class Networking.UserAgent
import Experiments
import class WidgetKit.WidgetCenter

import CocoaLumberjack
import KeychainAccess
import WordPressUI
import WordPressAuthenticator
import AutomatticTracks

import class Yosemite.ScreenshotStoresManager

// In that way, Inject will be available in the entire target.
@_exported import Inject

#if DEBUG
import Wormholy
#endif


// MARK: - Woo's App Delegate!
//
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// AppDelegate's Instance
    ///
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    /// Main Window
    ///
    var window: UIWindow?

    /// Coordinates app navigation based on authentication state.
    ///
    private var appCoordinator: AppCoordinator?

    /// Tab Bar Controller
    ///
    var tabBarController: MainTabBarController? {
        appCoordinator?.tabBarController
    }

    /// Coordinates the Jetpack setup flow for users authenticated without Jetpack.
    ///
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?

    private var universalLinkRouter: UniversalLinkRouter?

    private var waitingTimeTracker: AppStartupWaitingTimeTracker?

    // MARK: - AppDelegate Methods

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setup Components
        setupStartupWaitingTimeTracker()
        setupAnalytics()
        setupCocoaLumberjack()
        setupLibraryLogger()
        setupLogLevel(.verbose)
        setupPushNotificationsManagerIfPossible()
        setupAppRatingManager()
        setupWormholy()
        setupKeyboardStateProvider()
        handleLaunchArguments()
        setupUserNotificationCenter()

        // Components that require prior Auth
        setupZendesk()

        // Yosemite Initialization
        synchronizeEntitiesIfPossible()
        listenToApplicationPasswordGenerationFailureNotification()

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
        refreshCardPresentPaymentsOnboardingIfNeeded()

        // Silently connect to Tap to Pay if previously connected, to speed up IPP
        reconnectToTapToPayReaderIfNeeded()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup the Interface!
        setupMainWindow()
        setupComponentsAppearance()
        setupNoticePresenter()
        setupUniversalLinkRouter()
        disableAnimationsIfNeeded()

        // Start app navigation.
        appCoordinator?.start()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let rootViewController = window?.rootViewController else {
            fatalError()
        }

        if ServiceLocator.stores.isAuthenticatedWithoutWPCom,
           let site = ServiceLocator.stores.sessionManager.defaultSite {
            let coordinator = JetpackSetupCoordinator(site: site, rootViewController: rootViewController)
            jetpackSetupCoordinator = coordinator
            return coordinator.handleAuthenticationUrl(url)
        }
        return ServiceLocator.authenticationManager.handleAuthenticationUrl(url, options: options, rootViewController: rootViewController)
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

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

        // Cache onboarding state to speed IPP process
        refreshCardPresentPaymentsOnboardingIfNeeded()

        // Silently connect to Tap to Pay if previously connected, to speed up IPP
        reconnectToTapToPayReaderIfNeeded()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.

        RequirementsChecker.checkMinimumWooVersionForDefaultStore()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DDLogVerbose("👀 Application terminating...")
        NotificationCenter.default.post(name: .applicationTerminating, object: nil)
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            handleWebActivity(userActivity)
        }

        SpotlightManager.handleUserActivity(userActivity)
        trackWidgetTappedIfNeeded(userActivity: userActivity)

        return true
    }
}


// MARK: - Initialization Methods
//
private extension AppDelegate {

    /// Sets up the main UIWindow instance.
    ///
    func setupMainWindow() {
        let window = UIWindow()
        window.makeKeyAndVisible()
        self.window = window

        appCoordinator = AppCoordinator(window: window)
    }

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
        UISearchBar.applyWooAppearance()
        UITabBar.applyWooAppearance()

        // Take advantage of a bug in UIAlertController to style all UIAlertControllers with WC color
        window?.tintColor = .primary
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
    func setupAnalytics() {
        ServiceLocator.analytics.initialize()
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
        CocoaLumberjack.dynamicLogLevel = level
    }

    /// Setup: Notice Presenter
    ///
    func setupNoticePresenter() {
        var noticePresenter = ServiceLocator.noticePresenter
        noticePresenter.presentingViewController = appCoordinator?.tabBarController
    }

    /// Push Notifications: Authorization + Registration!
    ///
    func setupPushNotificationsManagerIfPossible() {
        let stores = ServiceLocator.stores
        guard stores.isAuthenticated,
              stores.needsDefaultStore == false,
              stores.isAuthenticatedWithoutWPCom == false else {
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.storeCreationNotifications) {
                ServiceLocator.pushNotesManager.ensureAuthorizationIsRequested(includesProvisionalAuth: true, onCompletion: nil)
            }
            return
        }

        #if targetEnvironment(simulator)
            DDLogVerbose("👀 Push Notifications are not supported in the Simulator!")
        #else
            let pushNotesManager = ServiceLocator.pushNotesManager
            pushNotesManager.registerForRemoteNotifications()
            pushNotesManager.ensureAuthorizationIsRequested(includesProvisionalAuth: false, onCompletion: nil)
        #endif
    }

    func setupUserNotificationCenter() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.storeCreationNotifications) else {
            return
        }
        UNUserNotificationCenter.current().delegate = self
    }

    func setupUniversalLinkRouter() {
        guard let tabBarController = tabBarController else { return }
        universalLinkRouter = UniversalLinkRouter.defaultUniversalLinkRouter(tabBarController: tabBarController)
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
        #if DEBUG
        /// We want to activate it programmatically, not using the shake.
        Wormholy.shakeEnabled = false
        #endif
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
        waitingTimeTracker = AppStartupWaitingTimeTracker()
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

    func refreshCardPresentPaymentsOnboardingIfNeeded() {
        ServiceLocator.cardPresentPaymentsOnboardingIPPUsersRefresher.refreshIPPUsersOnboardingState()
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

        ServiceLocator.stores.synchronizeEntities {
            NotificationCenter.default.post(name: .EntitiesSynchronized, object: nil)
        }
    }

    /// Deauthenticates the user upon application password generation failure.
    ///
    private func listenToApplicationPasswordGenerationFailureNotification() {
        guard ServiceLocator.stores.isAuthenticatedWithoutWPCom else {
            return
        }

        ServiceLocator.stores.listenToApplicationPasswordGenerationFailureNotification()
    }

    /// Runs whenever the Authentication Flow is completed successfully.
    ///
    func authenticatorWasDismissed() {
        setupPushNotificationsManagerIfPossible()
        RequirementsChecker.checkMinimumWooVersionForDefaultStore()
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

// MARK: - Universal Links

private extension AppDelegate {
    func handleWebActivity(_ activity: NSUserActivity) {
        guard let linkURL = activity.webpageURL else {
            return
        }

        universalLinkRouter?.handle(url: linkURL)
    }
}
