import XCTest
import Alamofire
@testable import Networking


/// Remote UnitTests
///
class RemoteTests: XCTestCase {

    /// Sample Credentials
    ///
    private let credentials = Credentials(authToken: "yosemite")

    /// Sample Request
    ///
    private let request = try! URLRequest(url: "www.a8c.com", method: .get)


    /// Verifies that `enqueue` properly wraps up the received request within an AuthenticatedRequest, with the remote credentials.
    ///
    func testEnqueueProperlyWrapsUpJsonRequestsIntoAuthenticatedRequestWithCredentials() {
        let network = MockupNetwork()
        let remote = Remote(network: network)
        let expectation = self.expectation(description: "Enqueue")

        remote.enqueue(request) { (payload, error) in
            XCTAssertNil(payload)
            XCTAssertEqual(error as! NetworkError, NetworkError.emptyResponse)

            XCTAssert(network.requestsForResponseData.isEmpty)
            XCTAssert(network.requestsForResponseJSON.count == 1)

            let first = network.requestsForResponseJSON.first as! AuthenticatedRequest
            XCTAssertNotNil(first)
            XCTAssertEqual(first.credentials, self.credentials)
            XCTAssertEqual(first.request as! URLRequest, self.request)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `enqueue:mapper:` properly wraps up the received request within an AuthenticatedRequest, with the remote credentials.
    ///
    func testEnqueueProperlyWrapsUpDataRequestsIntoAuthenticatedRequestWithCredentials() {
        let network = DummyNetwork()
        let mapper = DummyMapper()
        let remote = Remote(network: network)
        let expectation = self.expectation(description: "Enqueue with Mapper")

        remote.enqueue(request, mapper: mapper) { (payload, error) in
            XCTAssertNil(payload)
            XCTAssertEqual(error as! NetworkError, NetworkError.emptyResponse)

            XCTAssert(network.requestsForResponseJSON.isEmpty)
            XCTAssert(network.requestsForResponseData.count == 1)

            let first = network.requestsForResponseData.first as! AuthenticatedRequest
            XCTAssertNotNil(first)
            XCTAssertEqual(first.credentials, self.credentials)
            XCTAssertEqual(first.request as! URLRequest, self.request)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `enqueue:mapper:` relays any received payload over to the Mapper.
    ///
    func testEnqueueWithMapperProperlyRelaysReceivedPayloadToMapper() {
        let network = DummyNetwork()
        let mapper = DummyMapper()
        let remote = Remote(network: network)

        let expectation = self.expectation(description: "Enqueue with Mapper")

        let orderData = Loader.contentsOf("order")
        network.dummyDataResponse = orderData

        remote.enqueue(request, mapper: mapper) { (payload, error) in
            XCTAssertEqual(mapper.input, orderData)
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


/// Dummy Network: Useful only for Remote UnitTests
///
private class DummyNetwork: Network  {

    /// Keeps a collection of all of the `responseJSON` requests.
    ///
    var requestsForResponseJSON = [URLRequestConvertible]()

    /// Keeps a collection of all of the `responseData` requests.
    ///
    var requestsForResponseData = [URLRequestConvertible]()

    /// Dummy Data Response
    ///
    var dummyDataResponse: Data?


    func responseJSON(for request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        requestsForResponseJSON.append(request)
        completion(nil, nil)
    }

    func responseData(for request: URLRequestConvertible, completion: @escaping (Data?, Error?) -> Void) {
        requestsForResponseData.append(request)
        completion(dummyDataResponse, nil)
    }
}
