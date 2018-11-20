import XCTest
@testable import Networking


/// NotificationsRemote Tests
///
class NotificationsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that `loadNotes` properly returns all of the retrieved notifications.
    ///
    func testLoadNotesProperlyParsesRemoteNotifications() {
        let remote = NotificationsRemote(network: network)
        let expectation = self.expectation(description: "Load Notifications")

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")

        remote.loadNotes { (notes, error) in
            XCTAssertNotNil(notes)
            XCTAssertNil(error)
            XCTAssertEqual(notes?.count, 40)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
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
            let error = error as? DotcomError
            XCTAssertEqual(error?.code, "unknown_token")
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

        remote.updateReadStatus(noteIds: [], read: true) { error in
            let error = error as? DotcomError
            XCTAssertEqual(error?.code, "unknown_token")
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

        remote.updateReadStatus(noteIds: [], read: true) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
