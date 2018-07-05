import UIKit
import CoreData

import CocoaLumberjack
import Crashlytics
import Fabric
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



    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {

        // Setup the Interface!
        setupMainWindow()
        setupComponentsAppearance()

        // Setup Components
        setupAuthenticationManager()
        setupLogLevel(.verbose)

        // Display the Authentication UI
        displayAuthenticatorIfNeeded()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        Fabric.with([Crashlytics.self])

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
    }

    /// Sets up FancyButton's UIAppearance.
    ///
    func setupFancyButtonAppearance() {
        let appearance = FancyButton.appearance()
        appearance.titleFont = UIFont.font(forStyle: .headline, weight: .bold)
        appearance.primaryNormalBackgroundColor = StyleManager.buttonPrimaryColor
        appearance.primaryNormalBorderColor = StyleManager.buttonPrimaryHighlightedColor
        appearance.primaryHighlightBackgroundColor = StyleManager.buttonPrimaryHighlightedColor
        appearance.primaryHighlightBorderColor = StyleManager.buttonPrimaryHighlightedColor
        appearance.disabledBorderColor = StyleManager.buttonPrimaryHighlightedColor
        appearance.disabledBackgroundColor = StyleManager.buttonPrimaryHighlightedColor
    }

    /// Sets up the WordPress Authenticator.
    ///
    func setupAuthenticationManager() {
        authenticationManager.initialize()
    }

    /// Sets up CocoaLumberjack logging.
    ///
    func setupLogLevel(_ level: DDLogLevel) {
        DDLog.add(DDOSLogger.sharedInstance) // os_log based, iOS 10+

        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)

        let rawLevel = Int32(level.rawValue)

        WPSharedSetLoggingLevel(rawLevel)
        WPAuthenticatorSetLoggingLevel(rawLevel)
        WPKitSetLoggingLevel(rawLevel)

        // Test print each log level
        CocoaLumberjack.DDLogVerbose("Verbose")
        CocoaLumberjack.DDLogDebug("Debug")
        CocoaLumberjack.DDLogInfo("Info")
        CocoaLumberjack.DDLogWarn("Warn")
        CocoaLumberjack.DDLogError("Error")
    }
}


// MARK: - Authentication Methods
//
extension AppDelegate {

    /// Whenever there is no default WordPress.com Account, let's display the Authentication UI.
    ///
    func displayAuthenticatorIfNeeded() {
        guard needsAuthentication else {
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

    /// Indicates if there's a default WordPress.com account.
    ///
    var needsAuthentication: Bool {
        return CredentialsManager.shared.needsDefaultCredentials
    }
}
