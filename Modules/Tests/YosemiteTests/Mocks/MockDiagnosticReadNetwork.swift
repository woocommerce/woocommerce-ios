import Foundation
import protocol Alamofire.URLRequestConvertible
@testable import Networking
@testable import NetworkingCore

final class MockDiagnosticReadNetwork: MockNetwork, @unchecked Sendable {
    override func responseData(for request: URLRequestConvertible, completion: @escaping (Result<Data, Error>) -> Void) {
        // Keep existing path-based fixtures working when a diagnostic request wraps the original request.
        super.responseData(for: request.originalResponseRequest, completion: completion)
    }
}
