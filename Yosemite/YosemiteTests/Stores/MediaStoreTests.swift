import Photos
import XCTest
@testable import Yosemite
@testable import Networking

final class MediaStoreTests: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Product ID
    ///
    private let sampleProductID: Int64 = 586

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: test cases for `MediaAction.retrieveMediaLibrary`

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns the expected response.
    ///
    func testRetrieveMediaLibraryUponSuccessfulResponse() {
        let expectation = self.expectation(description: "Retrieve media library")

        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library")

        let expectedMedia = Media(mediaID: 2352,
                                  date: date(with: "2020-02-21T12:15:38+08:00"),
                                  fileExtension: "jpeg",
                                  mimeType: "image/jpeg",
                                  src: "https://test.com/wp-content/uploads/2020/02/img_0002-8.jpeg",
                                  thumbnailURL: "https://test.com/wp-content/uploads/2020/02/img_0002-8-150x150.jpeg",
                                  name: "DSC_0010",
                                  alt: "",
                                  height: nil,
                                  width: nil)

        let action = MediaAction.retrieveMediaLibrary(siteID: sampleSiteID,
                                                      pageNumber: 1,
                                                      pageSize: 20) { mediaItems, error in
                                                        XCTAssertNil(error)
                                                        XCTAssertEqual(mediaItems.count, 5)
                                                        XCTAssertEqual(mediaItems.first, expectedMedia)


                                                        expectation.fulfill()
        }

        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)
        mediaStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveMediaLibraryReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve media library")

        network.simulateResponse(requestUrlSuffix: "media", filename: "generic_error")
        let action = MediaAction.retrieveMediaLibrary(siteID: sampleSiteID,
                                                      pageNumber: 1,
                                                      pageSize: 20) { mediaItems, error in
                                                        XCTAssertNotNil(error)
                                                        XCTAssertNotNil(mediaItems)
                                                        XCTAssertTrue(mediaItems.isEmpty)
                                                        expectation.fulfill()
        }

        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)
        mediaStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is no backend response.
    ///
    func testRetrieveMediaLibraryReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve media library")

        let action = MediaAction.retrieveMediaLibrary(siteID: sampleSiteID,
                                                      pageNumber: 1,
                                                      pageSize: 20) { mediaItems, error in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)
        mediaStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
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
        let action = MediaAction.uploadMedia(siteID: sampleSiteID, productID: sampleProductID, mediaAsset: asset) { (uploadedMedia, error) in
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
        let action = MediaAction.uploadMedia(siteID: sampleSiteID, productID: sampleProductID, mediaAsset: asset) { (uploadedMedia, error) in
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

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.iso8601.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
