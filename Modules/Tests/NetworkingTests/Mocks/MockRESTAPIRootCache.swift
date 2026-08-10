@testable import NetworkingCore

final class MockRESTAPIRootCache: RESTAPIRootCaching {
    var stubbedRoot: String?

    init(stubbedRoot: String?) {
        self.stubbedRoot = stubbedRoot
    }

    func root(for siteURL: String) -> String? {
        stubbedRoot
    }

    func removeRoot(_ root: String, for siteURL: String) {
        guard stubbedRoot == root else { return }
        stubbedRoot = nil
    }
}
