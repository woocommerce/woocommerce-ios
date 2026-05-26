import Alamofire
import Combine
import TestKit
import XCTest
@testable import Networking
@testable import NetworkingCore

final class RefundsRemoteTests: XCTestCase {
    private let sampleSiteID: Int64 = 1234
    private let sampleOrderID: Int64 = 560

    func test_createRefund_returns_refund_on_success() async throws {
        // Given
        let network = MockNetwork()
        let remote = RefundsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds", filename: "refund-single")

        // When
        let refund = try await remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: sampleRefund())

        // Then
        XCTAssertEqual(refund.refundID, 562)
    }

    func test_createRefund_relays_network_error_when_response_data_is_present() async throws {
        // Given
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500,
                                                               response: Loader.contentsOf("refund-single"))
        let network = RefundCreationNetwork(error: expectedError, responseData: Loader.contentsOf("refund-single"))
        let remote = RefundsRemote(network: network)

        // When / Then
        await assertThrowsError({
            _ = try await remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: sampleRefund())
        }, errorAssert: { error in
            (error as? NetworkError) == expectedError
        })
    }
}

private extension RefundsRemoteTests {
    func sampleRefund() -> Refund {
        Refund(refundID: 0,
               orderID: sampleOrderID,
               siteID: sampleSiteID,
               dateCreated: Date(),
               amount: "18",
               reason: "",
               refundedByUserID: 0,
               isAutomated: nil,
               createAutomated: true,
               items: [],
               shippingLines: nil)
    }
}

private final class RefundCreationNetwork: Network {
    let error: Error
    let responseData: Data?
    var session: URLSession { URLSession(configuration: .default) }

    init(error: Error, responseData: Data?) {
        self.error = error
        self.responseData = responseData
    }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        completion(responseData, error)
    }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(error))
    }

    func responseDataAndHeaders(for request: URLRequestConvertible) async throws -> (Data, ResponseHeaders?) {
        throw error
    }

    func responseDataPublisher(for request: URLRequestConvertible) -> AnyPublisher<Result<Data, Error>, Never> {
        Just(.failure(error)).eraseToAnyPublisher()
    }

    func uploadMultipartFormData(multipartFormData: @escaping (NetworkingCore.MultipartFormData) -> Void,
                                 to request: URLRequestConvertible,
                                 completion: @escaping (Data?, Error?) -> Void) {
        completion(responseData, error)
    }
}
