import UIKit
@testable import WooCommerce
import Yosemite

@objc(TestingAppDelegate)
class TestingAppDelegate: AppDelegate {
    /// Enables mocking of `tabBarController` property in unit tests. It is strongly recommended to reset it back to `nil` after each test case that sets this.
    static var mockTabBarController: MainTabBarController?

    override var tabBarController: MainTabBarController? {
        Self.mockTabBarController ?? super.tabBarController
    }

    override func application(_ application: UIApplication,
                              willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Don't call super so nothing gets set up.

        let bundle = Bundle(for: type(of: self))
        let storyboard = UIStoryboard(name: "TestingMode", bundle: bundle)

        window = UIWindow()
        window?.rootViewController = storyboard.instantiateInitialViewController()
        window?.makeKeyAndVisible()

        return true
    }

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Don't call super so nothing gets set up.

        return true
    }
}
