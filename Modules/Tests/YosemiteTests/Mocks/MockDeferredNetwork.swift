import Alamofire
import Foundation
@testable import Networking
@testable import NetworkingCore

// `@unchecked`: `pendingResponses` is only read and written while holding `lock`. An `NSLock` rather than a `Mutex`,
// because the stored completions are not `Sendable`.
/// Holds the `responseData` completions until `deliverPendingResponses()` is called.
///
final class MockDeferredNetwork: MockNetwork, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingResponses: [() -> Void] = []

    override func responseData(for request: URLRequestConvertible, completion: @escaping (Swift.Result<Data, Error>) -> Void) {
        lock.withLock {
            pendingResponses.append {
                super.responseData(for: request, completion: completion)
            }
        }
    }

    func deliverPendingResponses() {
        let responses = lock.withLock {
            defer { pendingResponses = [] }
            return pendingResponses
        }
        responses.forEach { $0() }
    }
}
