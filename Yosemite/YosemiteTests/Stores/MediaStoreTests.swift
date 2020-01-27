import Photos
import XCTest
@testable import Yosemite
@testable import Networking

final class MediaStoreTests: XCTestCase {
    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    // MARK: test cases for `MediaAction.uploadMedia`

    /// Verifies that a nil SKU is valid.
    func testUploadingMedia() {
        let expectation = self.expectation(description: "Upload a media asset")
        let mediaStore = MediaStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let path = "sites/\(sampleSiteID)/media/new"

        network.simulateResponse(requestUrlSuffix: path, filename: "media-upload")

        let asset = PHAsset()
        let action = MediaAction.uploadMedia(siteID: sampleSiteID, mediaAsset: asset) { (uploadedMedia, error) in
            XCTAssertNotNil(uploadedMedia)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        mediaStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

private struct MockupExportableAsset: ExportableAsset {
}
