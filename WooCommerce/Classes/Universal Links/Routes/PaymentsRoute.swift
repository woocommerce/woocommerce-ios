import Foundation

/// Links an URL with a /payments path to the Payments Hub Menu
/// 
struct PaymentsRoute: Route {
    private let subPath = "/payments"
    private let tabBarController: MainTabBarController

    init(tabBarController: MainTabBarController) {
        self.tabBarController = tabBarController
    }

    func canHandle(subPath: String) -> Bool {
        return subPath == self.subPath
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        tabBarController.forwardPaymentsDeeplink(subPath: subPath)

        return true
    }
}
