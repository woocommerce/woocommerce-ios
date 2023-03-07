@testable import WooCommerce

final class MockRoute: Route {
    let subPath: String
    let performAction: ([String: String]) -> Bool

    init(subPath: String, performAction: @escaping ([String: String]) -> Bool) {
        self.subPath = subPath
        self.performAction = performAction
    }

    func perform(with parameters: [String: String]) -> Bool {
        performAction(parameters)
    }
}
