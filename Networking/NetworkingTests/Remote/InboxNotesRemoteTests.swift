import XCTest
@testable import Networking

final class InboxNotesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load all Inbox Notes tests

    /// Verifies that loadAllInboxNotes properly parses the `inbox-note-list` sample response.
    ///
    func test_loadAllInboxNotes_returns_parsed_inbox_notes() throws {
        // Given
        let remote = InboxNotesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "admin/notes", filename: "inbox-note-list")

        // When
        let result = waitFor { promise in
            remote.loadAllInboxNotes(for: self.sampleSiteID, pageNumber: 0, pageSize: 25) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let inboxNotes = try XCTUnwrap(result.get())
        XCTAssertEqual(inboxNotes.count, 24)
    }

    /// Verifies that loadAllInboxNotes uses the SiteID passed in for the request.
    ///
    func test_loadAllInboxNotes_uses_passed_siteID_for_request() throws {
        // Given
        let remote = InboxNotesRemote(network: network)

        // When
        remote.loadAllInboxNotes(for: sampleSiteID) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        XCTAssertEqual(request.siteID, sampleSiteID)
    }

    /// Verifies that loadAllInboxNotes uses the SiteID passed in to build the models.
    ///
    func test_loadAllInboxNotes_uses_passed_siteID_for_model_creation() throws {
        // Given
        let remote = InboxNotesRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "admin/notes", filename: "inbox-note-list")

        // When
        let result = waitFor { promise in
            remote.loadAllInboxNotes(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let inboxNotes = try result.get()
        XCTAssertEqual(inboxNotes.first?.siteID, sampleSiteID)
    }

    /// Verifies that loadAllInboxNotes properly relays Networking Layer errors.
    ///
    func test_loadAllInboxNotes_properly_relays_networking_errors() throws {
        // Given
        let remote = InboxNotesRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "admin/notes", error: error)

        // When
        let result = waitFor { promise in
            remote.loadAllInboxNotes(for: self.sampleSiteID,
                                  completion: { (result) in
                                    promise(result)
                                })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertNotNil(resultError)
    }
}
