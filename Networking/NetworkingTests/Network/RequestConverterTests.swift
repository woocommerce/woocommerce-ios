import XCTest
import Alamofire
@testable import Networking

final class RequestConvertorTests: XCTestCase {
    func test_jetpack_request_is_returned_when_credentials_not_available() {
        // Given
        let converter = RequestConverter(credentials: nil)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is JetpackRequest)
    }

    func test_jetpack_request_is_returned_for_WPCOM_credentials_when_available_as_REST_request() {
        // Given
        let credentials = Credentials(authToken: "secret")
        let converter = RequestConverter(credentials: credentials)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is JetpackRequest)
    }

    func test_jetpack_request_is_returned_for_WPCOM_credentials_when_not_available_as_REST_request() {
        // Given
        let credentials = Credentials(authToken: "secret")
        let converter = RequestConverter(credentials: credentials)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is JetpackRequest)
    }

    func test_REST_request_is_returned_for_WPOrg_credentials_when_available_as_REST_request() {
        // Given
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: "https://test.com/")
        let converter = RequestConverter(credentials: credentials)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is RESTRequest)
    }

    func test_jetpack_request_is_returned_for_WPOrg_credentials_when_not_available_as_REST_request() {
        // Given
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: "https://test.com/")
        let converter = RequestConverter(credentials: credentials)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        let request = converter.convert(jetpackRequest)

        // Then
        XCTAssertTrue(request is JetpackRequest)
    }
}
