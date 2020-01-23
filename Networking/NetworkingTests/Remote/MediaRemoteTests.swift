import XCTest
@testable import Networking

final class MediaRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - uploadMedia

    /// Verifies that `uploadMedia` properly parses the `media-upload` sample response.
    ///
    func testUploadMediaProperlyReturnsParsedMedia() {
        let remote = MediaRemote(network: network)
        let expectation = self.expectation(description: "Upload one media item")
        let path = "sites/\(sampleSiteID)/media/new"

        network.simulateResponse(requestUrlSuffix: path, filename: "media-upload")

        remote.uploadMedia(for: sampleSiteID,
                           mediaItems: []) { mediaItems, error in
            XCTAssertNil(error)
            XCTAssertNotNil(mediaItems)
            XCTAssertEqual(mediaItems?.count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `uploadMedia` properly relays Networking Layer errors.
    ///
    func testUploadMediaProperlyRelaysNetwokingErrors() {
        let remote = MediaRemote(network: network)
        let expectation = self.expectation(description: "Upload one media item")

        remote.uploadMedia(for: sampleSiteID,
                           mediaItems: []) { mediaItems, error in
            XCTAssertNil(mediaItems)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
