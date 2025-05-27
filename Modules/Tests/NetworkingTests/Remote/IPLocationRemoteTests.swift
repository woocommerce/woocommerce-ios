import XCTest
import TestKit
@testable import Networking


final class IPLocationRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    func test_country_code_is_correctly_parsed() {
        // Given
        let remote = IPLocationRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "geo/", filename: "ip-location")

        // When
        let countryCode = waitFor { promise in
            remote.getIPCountryCode { result in
                if case let .success(code) = result {
                    promise(code)
                }
            }
        }

        // Then
        XCTAssertEqual(countryCode, "CO")
    }
}
