import Synchronization
@testable import NetworkingCore

final class MockRESTAPIRootCache: RESTAPIRootCaching {
    private let root: Mutex<String?>

    var stubbedRoot: String? {
        get { root.withLock { $0 } }
        set { root.withLock { $0 = newValue } }
    }

    init(stubbedRoot: String?) {
        self.root = Mutex(stubbedRoot)
    }

    func root(for siteURL: String) -> String? {
        stubbedRoot
    }

    func removeRoot(_ root: String, for siteURL: String) {
        self.root.withLock { stubbedRoot in
            guard stubbedRoot == root else { return }
            stubbedRoot = nil
        }
    }
}
