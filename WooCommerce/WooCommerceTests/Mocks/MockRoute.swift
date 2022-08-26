@testable import WooCommerce

final class MockRoute: Route {
    let path: String
    let performAction: ([String: String]) -> ()

    init(path: String, performAction: @escaping ([String: String]) -> ()) {
        self.path = path
        self.performAction = performAction
    }

    func perform(with parameters: [String: String]) {
        performAction(parameters)
    }
}
