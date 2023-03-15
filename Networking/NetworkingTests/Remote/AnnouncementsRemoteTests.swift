import XCTest
@testable import Networking

final class AnnouncementsRemoteTests: XCTestCase {

    /// Mock network wrapper.
    private var network: MockNetwork!

    private var remote: AnnouncementsRemote!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = AnnouncementsRemote(network: network)
    }

    override func tearDown() {
        remote = nil
        network = nil
        super.tearDown()
    }

    func test_loadAnnouncements_returns_announcements_on_success() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "mobile/feature-announcements/", filename: "announcements")

        // When
        let result = waitFor { promise in
            self.remote.loadAnnouncements(appVersion: "10.7", locale: "en") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let announcements = try result.get()
        let firstItem = try XCTUnwrap(announcements.first)
        assertEqual("10.7", firstItem.appVersionName)
    }

    func test_loadAnnouncements_relays_error_on_failure() throws {
        // Given
        let expectedError = NetworkError.timeout
        network.simulateError(requestUrlSuffix: "mobile/feature-announcements/", error: expectedError)

        // When
        let result = waitFor { promise in
            self.remote.loadAnnouncements(appVersion: "10.7", locale: "en") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(result.isSuccess)
        let error = try XCTUnwrap(result.failure)
        assertEqual(expectedError, error as? NetworkError)
    }
}
