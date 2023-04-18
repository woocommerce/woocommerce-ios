@testable import WooCommerce

final class MockRoute: Route {
    let performAction: (_ subpath: String, _ parameters: [String: String]) -> Bool
    let handledSubpaths: [String]

    init(handledSubpaths: [String], performAction: @escaping (_ subpath: String, _ parameters: [String: String]) -> Bool) {
        self.handledSubpaths = handledSubpaths
        self.performAction = performAction
    }

    func canHandle(subPath: String) -> Bool {
        return handledSubpaths.contains { $0 == subPath }
    }

    func perform(for subPath: String, with parameters: [String: String]) -> Bool {
        performAction(subPath, parameters)
    }
}
