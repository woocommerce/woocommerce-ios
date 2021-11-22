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
    func test_retrieveMediaLibrary_returns_media_list() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library")
        let expectedMedia = Media(mediaID: 2352,
                                  date: date(with: "2020-02-21T12:15:38+08:00"),
                                  fileExtension: "jpeg",
                                  filename: "img_0002-8.jpeg",
                                  mimeType: "image/jpeg",
                                  src: "https://test.com/wp-content/uploads/2020/02/img_0002-8.jpeg",
                                  thumbnailURL: "https://test.com/wp-content/uploads/2020/02/img_0002-8-150x150.jpeg",
                                  name: "DSC_0010",
                                  alt: "",
                                  height: nil,
                                  width: nil)
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(siteID: self.sampleSiteID,
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 5)
        XCTAssertEqual(mediaItems.first, expectedMedia)
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns the expected response for cases where URLs contain special chars.
    ///
    func test_retrieveMediaLibrary_returns_media_list_when_URLs_contain_special_chars() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library")

        let expectedMedia = Media(mediaID: 2348,
                                  date: date(with: "2020-02-21T11:58:24+08:00"),
                                  fileExtension: "jpeg",
                                  filename: "img_0111-1-12-тест.jpeg",
                                  mimeType: "image/jpeg",
                                  src: "https://test.com/wp-content/uploads/2020/02/img_0111-1-12-тест.jpeg",
                                  thumbnailURL: "https://test.com/wp-content/uploads/2020/02/img_0111-1-12-тест-150x150.jpeg",
                                  name: "img_0111-1",
                                  alt: "",
                                  height: nil,
                                  width: nil)
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(siteID: self.sampleSiteID,
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 5)
        XCTAssertTrue(mediaItems.contains(expectedMedia))
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveMediaLibrary_returns_error_upon_response_error() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "media", filename: "generic_error")
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(siteID: self.sampleSiteID,
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unauthorized)
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is no backend response.
    ///
    func test_retrieveMediaLibrary_returns_error_upon_empty_response() {
        // Given
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)
        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(siteID: self.sampleSiteID,
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: test cases for `MediaAction.uploadMedia`

    func test_uploadMedia_returns_uploaded_media_and_deletes_input_media_file() throws {
        // Given

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

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.uploadMedia(siteID: self.sampleSiteID,
                                                 productID: self.sampleProductID,
                                                 mediaAsset: asset) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        _ = try XCTUnwrap(result.get())

        // Verifies that the temporary file is removed after the media is uploaded.
        XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))
    }

    func test_uploadMedia_returns_error_upon_response_error() {
        // Given
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

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.uploadMedia(siteID: self.sampleSiteID,
                                                 productID: self.sampleProductID,
                                                 mediaAsset: asset) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)

        // Verifies that the temporary file is removed after the media is uploaded.
        XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))
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
