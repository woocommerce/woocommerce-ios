import XCTest
import Alamofire
@testable import Networking


/// Remote UnitTests
///
class RemoteTests: XCTestCase {

    /// Sample Request
    ///
    private let request = try! URLRequest(url: "www.a8c.com/something", method: .get)


    /// Verifies that `enqueue:mapper:` properly wraps up the received request within an AuthenticatedRequest, with
    /// the remote credentials.
    ///
    func testEnqueueProperlyWrapsUpDataRequestsIntoAuthenticatedRequestWithCredentials() {
        let network = MockupNetwork()
        let mapper = DummyMapper()
        let remote = Remote(network: network)
        let expectation = self.expectation(description: "Enqueue with Mapper")

        remote.enqueue(request, mapper: mapper) { (payload, error) in
            guard case NetworkError.notFound? = error else {
                XCTFail()
                return
            }

            XCTAssertNil(payload)

            XCTAssert(network.requestsForResponseData.count == 1)

            let first = network.requestsForResponseData.first as! URLRequest
            XCTAssertNotNil(first)
            XCTAssertEqual(first, self.request)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that `enqueue:mapper:` relays any received payload over to the Mapper.
    ///
    func testEnqueueWithMapperProperlyRelaysReceivedPayloadToMapper() {
        let network = MockupNetwork()
        let mapper = DummyMapper()
        let remote = Remote(network: network)

        let expectation = self.expectation(description: "Enqueue with Mapper")

        network.simulateResponse(requestUrlSuffix: "something", filename: "order")

        remote.enqueue(request, mapper: mapper) { (payload, error) in
            XCTAssertEqual(mapper.input, Loader.contentsOf("order"))
            XCTAssertNotNil(mapper.input)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    /// Verifies that `enqueue:` posts a `RemoteDidReceiveApplicationError` Notification whenever the backend returns a
    /// Request Timeout error.
    ///
    func testEnqueueRequestWithoutMapperPostsApplicationErrorNotificationWhenTheResponseContainsTimeoutError() {
        let network = MockupNetwork()
        let remote = Remote(network: network)

        let expectationForNotification = expectation(forNotification: .RemoteDidReceiveApplicationError, object: nil, handler: nil)
        let expectationForRequest = expectation(description: "Request")

        network.simulateResponse(requestUrlSuffix: "something", filename: "timeout_error")

        remote.enqueue(request) { (payload, error) in
            XCTAssertNil(payload)
            XCTAssert(error is DotcomError)
            expectationForRequest.fulfill()
        }

        wait(for: [expectationForNotification, expectationForRequest], timeout: Constants.expectationTimeout)
    }


    /// Verifies that `enqueue:mapper:` posts a `RemoteDidReceiveApplicationError` Notification whenever the backend returns a
    /// Request Timeout error.
    ///
    func testEnqueueRequestWithMapperPostsApplicationErrorNotificationWhenTheResponseContainsTimeoutError() {
        let network = MockupNetwork()
        let mapper = DummyMapper()
        let remote = Remote(network: network)

        let expectationForNotification = expectation(forNotification: .RemoteDidReceiveApplicationError, object: nil, handler: nil)
        let expectationForRequest = expectation(description: "Request")

        network.simulateResponse(requestUrlSuffix: "something", filename: "timeout_error")

        remote.enqueue(request, mapper: mapper) { (payload, error) in
            XCTAssertNil(payload)
            XCTAssert(error is DotcomError)
            expectationForRequest.fulfill()
        }

        wait(for: [expectationForNotification, expectationForRequest], timeout: Constants.expectationTimeout)

    }
}


/// Dummy Mapper: Useful only for Remote UnitTests
///
private class DummyMapper: Mapper {

    /// Contains the last received `response` (via the map method).
    ///
    var input: Data?

    func map(response: Data) throws -> Any {
        input = response
        return response
    }
}
