import XCTest
@testable import Networking


/// NotificationsRemote Tests
///
final class NotificationsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that `loadNotes` properly returns all of the retrieved notifications.
    ///
    func testLoadNotesProperlyParsesRemoteNotifications() throws {
        // Given
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Load Notifications")

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")

        // When
        var resultMaybe: Result<[Note], Error>?
        remote.loadNotes { aResult in
            resultMaybe = aResult
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        let result = try XCTUnwrap(resultMaybe)
        XCTAssertTrue(result.isSuccess)

        let notes = try result.get()
        XCTAssertEqual(notes.count, 40)
    }

    /// Verifies that `loadHashes` properly returns all of the retrieved hashes.
    ///
    func testLoadHashesProperlyParsesRemoteHashes() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Load Hashes")

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-hashes")

        remote.loadHashes { (notes, error) in
            XCTAssertNotNil(notes)
            XCTAssertNil(error)
            XCTAssertEqual(notes?.count, 40)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadHashes` correctly returns an error, whenever the network request fails.
    ///
    func testLoadHashesProperlyRelaysAnyRemoteErrors() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Error Handling")

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "generic_error")

        remote.loadHashes { (notes, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(notes)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `updateLastSeen` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func testUpdateLastSeenProperlyParsesErrorResponses() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Error Handling")

        network.simulateResponse(requestUrlSuffix: "notifications/seen", filename: "generic_error")

        remote.updateLastSeen("") { error in
            guard let error = error as? DotcomError else {
                XCTFail()
                return
            }

            XCTAssert(error == .unauthorized)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `updateLastSeen` correctly parses a successful response.
    ///
    func testUpdateLastSeenProperlyParsesSuccessResponses() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Error Handling")

        network.simulateResponse(requestUrlSuffix: "notifications/seen", filename: "generic_success")

        remote.updateLastSeen("") { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `updateReadStatus` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func testUpdateReadStatusProperlyParsesErrorResponses() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Error Handling")

        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_error")

        remote.updateReadStatus(noteIDs: [], read: true) { error in
            guard let error = error as? DotcomError else {
                XCTFail()
                return
            }

            XCTAssert(error == .unauthorized)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `updateReadStatus` correctly parses a successful response.
    ///
    func testUpdateReadStatusProperlyParsesSuccessResponses() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Error Handling")

        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_success")

        remote.updateReadStatus(noteIDs: [], read: true) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
