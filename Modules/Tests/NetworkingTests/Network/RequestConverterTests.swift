import XCTest
import Alamofire
@testable import Networking
@testable import NetworkingCore

final class RequestConvertorTests: XCTestCase {
    func test_jetpack_request_is_returned_when_site_address_not_available() {
        // Given
        let converter = RequestConverter(siteAddress: nil)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is JetpackRequest)
    }

    func test_REST_request_is_returned_when_site_address_is_available_and_jetpack_request_is_available_as_REST_request() {
        // Given
        let converter = RequestConverter(siteAddress: "https://test.com/")
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is RESTRequest)
    }

    func test_jetpack_request_is_returned_when_not_available_as_REST_request() {
        // Given
        let converter = RequestConverter(siteAddress: "https://test.com/")
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is JetpackRequest)
    }
}
