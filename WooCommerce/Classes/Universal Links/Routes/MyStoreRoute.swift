import Foundation
import Yosemite

/// Shows My Store from a given universal link that matches the right path
///
struct MyStoreRoute: Route {
    func canHandle(subPath: String) -> Bool {
        return subPath == ""
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        MainTabBarController.switchToMyStoreTab()

        return true
    }
}
