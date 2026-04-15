import UIKit
import Combine
import Storage
import class Networking.UserAgent
import class Networking.BackgroundCatalogDownloadCoordinator
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
        return UIApplication.sceneDelegate?.tabBarController
    }

    /// Coordinates the Jetpack setup flow for users authenticated without Jetpack.
    ///
    private var jetpackSetupCoordinator: JetpackSetupCoordinator?

    /// Coordinates the setup flow for self-driven push notification system
    private var wooPushNotificationCoordinator: WooPushNotificationSetupCoordinator?

    private(set) lazy var requirementsChecker = RequirementsChecker(baseViewController: tabBarController)

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

        /// This is important to initialize early as there are a few code points where the authenticator is used.
        ServiceLocator.authenticationManager.initialize()
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
        refreshCardPresentPaymentsOnboardingIfNeeded()

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

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        ServiceLocator.pushNotesManager.registerDeviceToken(with: deviceToken)
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

    func applicationWillTerminate(_ application: UIApplication) {
        DDLogVerbose("👀 Application terminating...")
        NotificationCenter.default.post(name: .applicationTerminating, object: nil)
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        let size = os_proc_available_memory()
        DDLogDebug("Received memory warning: Available memory - \(size)")
        ServiceLocator.imageService.clearMemoryCache()
    }

    /// Handles background URLSession events for downloads that continue while the app is suspended.
    /// This is required for background catalog downloads in POS to complete successfully.
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        DDLogInfo("🟣 Handling background URLSession events for identifier: \(identifier)")

        if identifier.hasPrefix("com.woocommerce.pos.catalog.download") {
            // Handle POS catalog download completion in background
            Task {
                let downloadCoordinator = BackgroundCatalogDownloadCoordinator()
                await downloadCoordinator.handleBackgroundSessionEvent(
                    sessionIdentifier: identifier,
                    completionHandler: completionHandler,
                    parseHandler: { fileURL, siteID in
                        // Use the POS catalog sync coordinator to parse and persist
                        guard let coordinator = ServiceLocator.stores.posCatalogSyncCoordinator else {
                            throw NSError(domain: "com.woocommerce.pos", code: -1,
                                         userInfo: [NSLocalizedDescriptionKey: "POS catalog coordinator not available"])
                        }
                        try await coordinator.processBackgroundDownload(fileURL: fileURL, siteID: siteID)
                    }
                )
            }
        } else {
            // Unknown session identifier - call completion handler immediately
            DDLogWarn("🟣 Unknown background URLSession identifier: \(identifier)")
            completionHandler()
        }
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

    /// Sets up app analytics.
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
    // periphery: ignore - Fails when build on simulator
    func setupPushNotificationsManagerIfPossible(_ pushNotesManager: PushNotesManager, stores: StoresManager) {
        /// We're sending notifications for logged in state only.
        /// Revisit this check if a local notification in unauthenticated state is needed.
        guard stores.isAuthenticated else { return }
        let pushNotesManager = ServiceLocator.pushNotesManager
        pushNotesManager.registerForRemoteNotifications()
        pushNotesManager.ensureAuthorizationIsRequested(includesProvisionalAuth: false, onCompletion: nil)
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

    func refreshCardPresentPaymentsOnboardingIfNeeded() {
        ServiceLocator
            .cardPresentPaymentsOnboardingIPPUsersRefresher
            .refreshIPPUsersOnboardingState(completion: reconnectToTapToPayReaderIfNeeded)
    }

    func reconnectToTapToPayReaderIfNeeded() {
        ServiceLocator.tapToPayReconnectionController.reconnectIfNeeded()
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
        if stores.isAuthenticatedWithoutWPCom == false {
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
        if ServiceLocator.stores.isAuthenticated {
            let pendingAuthFlowStorage = PendingAuthFlowStorage()
            let flow = pendingAuthFlowStorage.current
            pendingAuthFlowStorage.clear()

            switch flow {
            case .jetpackSetup:
                return handleAuthenticationUrlForJetpackSetup(url, rootViewController: rootViewController)
            case .none:
                return false
            }
        } else {
            return ServiceLocator.authenticationManager.handleAuthenticationUrl(url, options: options, rootViewController: rootViewController)
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
