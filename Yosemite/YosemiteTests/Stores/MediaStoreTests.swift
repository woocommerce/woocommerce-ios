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

    func testUploadingMedia() {
        let expectation = self.expectation(description: "Upload a media asset")

        // Creates a temporary file to simulate a uploadable media file.
        let filename = "test.txt"
        let fileManager = FileManager.default
        let targetURL = fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)

        do {
            try fileManager.createDirectory(at: fileManager.temporaryDirectory, withIntermediateDirectories: true)
            try "testing".write(toFile: targetURL.path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            XCTFail("Cannot write to target URL: \(targetURL) with error: \(error)")
        }

        // Verifies that the temporary file exists.
        XCTAssertTrue(fileManager.fileExists(atPath: targetURL.path))

        let uploadableMedia = createSampleUploadableMedia(targetURL: targetURL)
        let mediaExportService = MockMediaExportService(uploadableMedia: uploadableMedia)
        let mediaStore = MediaStore(mediaExportService: mediaExportService,
                                    dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        let path = "sites/\(sampleSiteID)/media/new"

        network.simulateResponse(requestUrlSuffix: path, filename: "media-upload")

        let asset = PHAsset()
        let action = MediaAction.uploadMedia(siteID: sampleSiteID, mediaAsset: asset) { (uploadedMedia, error) in
            XCTAssertNotNil(uploadedMedia)
            XCTAssertNil(error)

            // Verifies that the temporary file is removed after the media is uploaded.
            XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))

            expectation.fulfill()
        }

        mediaStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    func testUploadingMediaWithErrorUponReponseError() {
        let expectation = self.expectation(description: "Upload a media asset")

        // Creates a temporary file to simulate a uploadable media file.
        let filename = "test.txt"
        let fileManager = FileManager.default
        let targetURL = fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)

        do {
            try fileManager.createDirectory(at: fileManager.temporaryDirectory, withIntermediateDirectories: true)
            try "testing".write(toFile: targetURL.path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            XCTFail("Cannot write to target URL: \(targetURL) with error: \(error)")
        }

        // Verifies that the temporary file exists.
        XCTAssertTrue(fileManager.fileExists(atPath: targetURL.path))

        let uploadableMedia = createSampleUploadableMedia(targetURL: targetURL)
        let mediaExportService = MockMediaExportService(uploadableMedia: uploadableMedia)
        let mediaStore = MediaStore(mediaExportService: mediaExportService,
                                    dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        let path = "sites/\(sampleSiteID)/media/new"

        network.simulateResponse(requestUrlSuffix: path, filename: "generic_error")

        let asset = PHAsset()
        let action = MediaAction.uploadMedia(siteID: sampleSiteID, mediaAsset: asset) { (uploadedMedia, error) in
            XCTAssertNil(uploadedMedia)
            XCTAssertNotNil(error)

            // Verifies that the temporary file is removed after the media is uploaded.
            XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))

            expectation.fulfill()
        }

        mediaStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}

private extension MediaStoreTests {
    func createSampleUploadableMedia(targetURL: URL) -> UploadableMedia {
        return UploadableMedia(localURL: targetURL,
                               filename: "test.jpg",
                               mimeType: "image/jpeg")
    }
}
