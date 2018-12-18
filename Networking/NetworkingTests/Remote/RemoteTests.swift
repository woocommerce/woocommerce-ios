import XCTest
import Alamofire
@testable import Networking


/// Remote UnitTests
///
class RemoteTests: XCTestCase {

    /// Sample Request
    ///
    private let request = try! URLRequest(url: "www.a8c.com/something", method: .get)


    /// Verifies that `enqueue` properly wraps up the received request within an AuthenticatedRequest, with the remote credentials.
    ///
    func testEnqueueProperlyWrapsUpJsonRequestsIntoAuthenticatedRequestWithCredentials() {
        let network = MockupNetwork()
        let remote = Remote(network: network)
        let expectation = self.expectation(description: "Enqueue")

        remote.enqueue(request) { (payload, error) in
            XCTAssertNil(payload)
            guard case NetworkError.notFound? = error else {
                XCTFail()
                return
            }

            XCTAssert(network.requestsForResponseData.isEmpty)
            XCTAssert(network.requestsForResponseJSON.count == 1)

            let first = network.requestsForResponseJSON.first as! URLRequest
            XCTAssertNotNil(first)
            XCTAssertEqual(first, self.request)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `enqueue:mapper:` properly wraps up the received request within an AuthenticatedRequest, with the remote credentials.
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

            XCTAssert(network.requestsForResponseJSON.isEmpty)
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
