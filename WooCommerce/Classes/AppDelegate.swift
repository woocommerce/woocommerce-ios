import UIKit
import CoreData
import Storage

import CocoaLumberjack
import WordPressUI
import WordPressKit
import WordPressAuthenticator
import AutomatticTracks


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

    /// Tab Bar Controller
    ///
    var tabBarController: MainTabBarController? {
        return window?.rootViewController as? MainTabBarController
    }

    /// Store Picker Coordinator
    ///
    private var storePickerCoordinator: StorePickerCoordinator?


    // MARK: - AppDelegate Methods

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // Setup the Interface!
        setupMainWindow()
        setupComponentsAppearance()

        // Setup Components
        setupCrashLogging()
        setupAnalytics()
        setupAuthenticationManager()
        setupCocoaLumberjack()
        setupLogLevel(.verbose)
        setupNoticePresenter()
        setupPushNotificationsManagerIfPossible()
        setupAppRatingManager()

        // Display the Authentication UI
        displayAuthenticatorIfNeeded()
        displayStorePickerIfNeeded()

        // Components that require prior Auth
        setupZendesk()

        // Yosemite Initialization
        synchronizeEntitiesIfPossible()

        // Upgrade check...
        checkForUpgrades()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let rootViewController = window?.rootViewController else {
            fatalError()
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

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        ServiceLocator.pushNotesManager.handleNotification(userInfo, completionHandler: completionHandler)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
        // Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
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
}


// MARK: - Initialization Methods
//
private extension AppDelegate {

    /// Sets up the main UIWindow instance.
    ///
    func setupMainWindow() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Main is the name of storyboard

        window = UIWindow()
        window?.rootViewController = storyboard.instantiateInitialViewController()
        window?.makeKeyAndVisible()
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
        appearance.bodyBackgroundColor = .listBackground
        appearance.bottomBackgroundColor = .listBackground
        appearance.bottomDividerColor = .listSmallIcon
        appearance.topDividerColor = .listSmallIcon

        appearance.titleTextColor = .text
        appearance.titleFont = UIFont.title2

        appearance.bodyTextColor = .text
        appearance.bodyFont = UIFont.body

        appearance.actionFont = UIFont.headline
        appearance.infoFont = UIFont.subheadline
        appearance.infoTintColor = .primary
        appearance.headerBackgroundColor = .listSmallIcon
    }

    /// Sets up FancyButton's UIAppearance.
    ///
    func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.primaryNormalBackgroundColor = .primaryButtonBackground
        appearance.primaryNormalBorderColor = .primaryButtonDownBorder
        appearance.primaryHighlightBackgroundColor = .primaryButtonDownBackground
        appearance.primaryHighlightBorderColor = .primaryButtonDownBorder
    }

    /// Sets up Crash Logging
    ///
    func setupCrashLogging() {
        CrashLogging.start(withDataProvider: WCCrashLoggingDataProvider())
    }

    /// Sets up the Zendesk SDK.
    ///
    func setupZendesk() {
        ZendeskManager.shared.initialize()
    }

    /// Sets up the WordPress Authenticator.
    ///
    func setupAnalytics() {
        ServiceLocator.analytics.initialize()
    }

    /// Sets up the WordPress Authenticator.
    ///
    func setupAuthenticationManager() {
        ServiceLocator.authenticationManager.initialize()
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

    /// Sets up the current Log Leve.
    ///
    func setupLogLevel(_ level: DDLogLevel) {
        let rawLevel = Int32(level.rawValue)

        WPSharedSetLoggingLevel(rawLevel)
        WPAuthenticatorSetLoggingLevel(rawLevel)
        WPKitSetLoggingLevel(rawLevel)
    }

    /// Setup: Notice Presenter
    ///
    func setupNoticePresenter() {
        var noticePresenter = ServiceLocator.noticePresenter
        noticePresenter.presentingViewController = window?.rootViewController
    }

    /// Push Notifications: Authorization + Registration!
    ///
    func setupPushNotificationsManagerIfPossible() {
        guard ServiceLocator.stores.isAuthenticated, ServiceLocator.stores.needsDefaultStore == false else {
            return
        }

        #if targetEnvironment(simulator)
            DDLogVerbose("👀 Push Notifications are not supported in the Simulator!")
        #else
            let pushNotesManager = ServiceLocator.pushNotesManager
            pushNotesManager.registerForRemoteNotifications()
            pushNotesManager.ensureAuthorizationIsRequested(onCompletion: nil)
        #endif
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
}


// MARK: - Minimum Version
//
private extension AppDelegate {

    func checkForUpgrades() {
        let currentVersion = UserAgent.bundleShortVersion
        let versionOfLastRun = UserDefaults.standard[.versionOfLastRun] as? String
        if versionOfLastRun == nil {
            // First run after a fresh install
            ServiceLocator.analytics.track(.applicationInstalled)
        } else if versionOfLastRun != currentVersion {
            // App was upgraded
            ServiceLocator.analytics.track(.applicationInstalled, withProperties: ["previous_version": versionOfLastRun ?? String()])
        }

        UserDefaults.standard[.versionOfLastRun] = currentVersion
    }
}


// MARK: - Authentication Methods
//
extension AppDelegate {

    /// Whenever there is no default WordPress.com Account, let's display the Authentication UI.
    ///
    func displayAuthenticatorIfNeeded() {
        guard ServiceLocator.stores.isAuthenticated == false else {
            return
        }

        displayAuthenticator()
    }

    /// Displays the WordPress.com Authentication UI.
    ///
    func displayAuthenticator() {
        guard let rootViewController = window?.rootViewController else {
            fatalError()
        }

        ServiceLocator.authenticationManager.displayAuthentication(from: rootViewController)
    }

    /// Whenever the app is authenticated but there is no Default StoreID: Let's display the Store Picker.
    ///
    func displayStorePickerIfNeeded() {
        guard ServiceLocator.stores.isAuthenticated, ServiceLocator.stores.needsDefaultStore else {
            return
        }
        guard let tabBar = AppDelegate.shared.tabBarController,
            let navigationController = tabBar.selectedViewController as? UINavigationController else {
                DDLogError("⛔️ Unable to locate navigationController in order to launch the store picker.")
            return
        }

        DDLogInfo("💬 Authenticated user does not have a Woo store selected — launching store picker.")
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .standard)
        storePickerCoordinator?.start()
    }

    /// Whenever we're in an Authenticated state, let's Sync all of the WC-Y entities.
    ///
    func synchronizeEntitiesIfPossible() {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }

        ServiceLocator.stores.synchronizeEntities(onCompletion: nil)
    }

    /// Runs whenever the Authentication Flow is completed successfully.
    ///
    func authenticatorWasDismissed() {
        setupPushNotificationsManagerIfPossible()
        RequirementsChecker.checkMinimumWooVersionForDefaultStore()
    }
}
