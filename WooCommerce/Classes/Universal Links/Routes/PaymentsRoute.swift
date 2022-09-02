import Foundation

/// Links an URL with a /payments path to the Payments Hub Menu
/// 
struct PaymentsRoute: Route {
    let path = "/payments"

    func perform(with parameters: [String: String]) -> Bool {
        MainTabBarController.presentPayments()

        return true
    }
}
