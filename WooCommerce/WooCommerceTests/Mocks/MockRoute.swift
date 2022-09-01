@testable import WooCommerce

final class MockRoute: Route {
    let path: String
    let performAction: ([String: String]) -> Bool

    init(path: String, performAction: @escaping ([String: String]) -> Bool) {
        self.path = path
        self.performAction = performAction
    }

    func perform(with parameters: [String: String]) -> Bool {
        performAction(parameters)
    }
}
