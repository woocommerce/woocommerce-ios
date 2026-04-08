@testable import NetworkingCore

struct MockRESTAPIRootCache: RESTAPIRootCaching {
    var stubbedRoot: String?

    func root(for siteURL: String) -> String? {
        stubbedRoot
    }
}
