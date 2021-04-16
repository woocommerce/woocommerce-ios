import XCTest
@testable import Networking

final class MediaRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Product ID
    ///
    private let sampleProductID: Int64 = 586

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load Media From Media Library `loadMediaLibrary`

    /// Verifies that `loadMediaLibrary` properly parses the `media-library` sample response.
    ///
    func testLoadMediaLibraryProperlyReturnsParsedMedia() {
        let remote = MediaRemote(network: network)
        let expectation = self.expectation(description: "Load Media Library")

        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library")

        remote.loadMediaLibrary(for: sampleSiteID) { mediaItems, error in
            XCTAssertNil(error)
            XCTAssertNotNil(mediaItems)
            XCTAssertEqual(mediaItems?.count, 5)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadMediaLibrary` properly relays Networking Layer errors.
    ///
    func testLoadMediaLibraryProperlyRelaysNetwokingErrors() {
        let remote = MediaRemote(network: network)
        let expectation = self.expectation(description: "Load Media Library")

        remote.loadMediaLibrary(for: sampleSiteID) { mediaItems, error in
            XCTAssertNil(mediaItems)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
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
                           productID: sampleProductID,
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
                           productID: sampleProductID,
                           mediaItems: []) { mediaItems, error in
            XCTAssertNil(mediaItems)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
