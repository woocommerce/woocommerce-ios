import UIKit
import CoreData
import Storage

import CocoaLumberjack
import WordPressUI
import WordPressKit
import WordPressAuthenticator



// MARK: - Woo's App Delegate!
//
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// AppDelegate's Instance
    ///
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    /// Main Window
    ///
    var window: UIWindow?

    /// WordPressAuthenticator Wrapper
    ///
    let authenticationManager = AuthenticationManager()

    /// Fabric: Crash Reporting
    ///
    let fabricManager = FabricManager()

    /// In-App Notifications Presenter
    ///
    let noticePresenter = NoticePresenter()

    /// CoreData Stack
    ///
    let storageManager = CoreDataManager(name: WooConstants.databaseStackName)

    /// Tab Bar Controller
    ///
    var tabBarController: MainTabBarController? {
        guard let window = window,
            let tabBar = window.rootViewController as? MainTabBarController else {
                return nil
        }

        return tabBar
    }



    // MARK: - AppDelegate Methods

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {

        // Setup the Interface!
        setupMainWindow()
        setupComponentsAppearance()

        // Setup Components
        setupFabric()
        setupAnalytics()
        setupAuthenticationManager()
        setupCocoaLumberjack()
        setupLogLevel(.verbose)
        setupNoticePresenter()

        // Display the Authentication UI
        displayAuthenticatorIfNeeded()
        displayStorePickerIfNeeded()

        // Yosemite Initialization
        synchronizeEntitiesIfPossible()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let rootViewController = window?.rootViewController else {
            fatalError()
        }

        return authenticationManager.handleAuthenticationUrl(url, options: options, rootViewController: rootViewController)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {

    }
}


// MARK: - Initialization Methods
//
private extension AppDelegate {

    /// Sets up the main UIWindow instance.
    ///
    func setupMainWindow() {
        window?.makeKeyAndVisible()
    }

    /// Sets up all of the component(s) Appearance.
    ///
    func setupComponentsAppearance() {
        setupWooAppearance()
        setupFancyButtonAppearance()
    }

    /// Sets up WooCommerce's UIAppearance.
    ///
    func setupWooAppearance() {
        UINavigationBar.appearance().barTintColor = StyleManager.wooCommerceBrandColor
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = .white
        UIApplication.shared.statusBarStyle = .lightContent

        // Take advantage of a bug in UIAlertController
        // to style all UIAlertControllers with WC color
        window?.tintColor = StyleManager.wooCommerceBrandColor
    }

    /// Sets up FancyButton's UIAppearance.
    ///
    func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.primaryNormalBackgroundColor = StyleManager.buttonPrimaryColor
        appearance.primaryNormalBorderColor = StyleManager.buttonPrimaryHighlightedColor
        appearance.primaryHighlightBackgroundColor = StyleManager.buttonPrimaryHighlightedColor
        appearance.primaryHighlightBorderColor = StyleManager.buttonPrimaryHighlightedColor
    }

    /// Sets up the Fabric SDK.
    ///
    func setupFabric() {
        fabricManager.initialize()
        fabricManager.startListeningToAuthNotifications()
    }

    /// Sets up the WordPress Authenticator.
    ///
    func setupAnalytics() {
        WooAnalytics.shared.initialize()
    }

    /// Sets up the WordPress Authenticator.
    ///
    func setupAuthenticationManager() {
        authenticationManager.initialize()
    }

    /// Sets up CocoaLumberjack logging.
    ///
    func setupCocoaLumberjack() {
        let fileLogger: DDFileLogger = DDFileLogger()
        fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7

        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(fileLogger)
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
        noticePresenter.presentingViewController = window?.rootViewController
    }
}


// MARK: - Authentication Methods
//
extension AppDelegate {

    /// Whenever there is no default WordPress.com Account, let's display the Authentication UI.
    ///
    func displayAuthenticatorIfNeeded() {
        guard StoresManager.shared.isAuthenticated == false else {
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

        authenticationManager.displayAuthentication(from: rootViewController)
    }

    /// Whenever the app is authenticated but there is no Default StoreID: Let's display the Store Picker.
    ///
    func displayStorePickerIfNeeded() {
        guard StoresManager.shared.isAuthenticated, StoresManager.shared.needsDefaultStore else {
            return
        }

        displayStorePicker()
    }

    /// Displays the Woo Store Picker.
    ///
    func displayStorePicker() {
        let pickerViewController = StorePickerViewController()
        let navigationController = UINavigationController(rootViewController: pickerViewController)

        window?.rootViewController?.present(navigationController, animated: true, completion: nil)
    }

    /// Whenever we're in an Authenticated state, let's Sync all of the WC-Y entities.
    ///
    func synchronizeEntitiesIfPossible() {
        guard StoresManager.shared.isAuthenticated else {
            return
        }

        StoresManager.shared.synchronizeEntities()
    }
}
