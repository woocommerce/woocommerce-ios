import Alamofire
import Foundation
@testable import Networking
@testable import NetworkingCore

/// Holds the `responseData` completions until `deliverPendingResponses()` is called.
///
final class MockDeferredNetwork: MockNetwork {
    private var pendingResponses: [() -> Void] = []

    override func responseData(for request: URLRequestConvertible, completion: @escaping (Swift.Result<Data, Error>) -> Void) {
        pendingResponses.append {
            super.responseData(for: request, completion: completion)
        }
    }

    func deliverPendingResponses() {
        let responses = pendingResponses
        pendingResponses = []
        responses.forEach { $0() }
    }
}
