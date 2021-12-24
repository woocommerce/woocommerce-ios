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

    /// Verifies that `MediaAction.retrieveMediaLibrary` invokes `MediaRemoteProtocol.loadMediaLibrary` when there is no corresponding site in storage.
    func test_retrieveMediaLibrary_without_storage_site_invokes_loadMediaLibrary_remote_call() throws {
        // Given
        let remote = MockMediaRemote()
        remote.whenLoadingMediaLibrary(siteID: sampleSiteID, thenReturn: .success([]))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        // When
        let _: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(siteID: self.sampleSiteID,
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadMediaLibrary(siteID: sampleSiteID)])
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` from a JCP site returns the media list from the remote response.
    func test_retrieveMediaLibrary_from_jcp_site_returns_media_list() throws {
        // Given
        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenLoadingMediaLibraryFromWordPressSite(siteID: sampleSiteID, thenReturn: .success([media]))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        insertJCPSiteToStorage(siteID: sampleSiteID)

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
        XCTAssertEqual(remote.invocations, [.loadMediaLibraryFromWordPressSite(siteID: sampleSiteID)])

        let mediaList = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaList, [media.toMedia()])
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` from a JCP site returns an error from the remote response.
    func test_retrieveMediaLibrary_from_jcp_site_returns_error_upon_empty_response() throws {
        // Given
        let remote = MockMediaRemote()
        remote.whenLoadingMediaLibraryFromWordPressSite(siteID: sampleSiteID, thenReturn: .failure(DotcomError.unauthorized))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        insertJCPSiteToStorage(siteID: sampleSiteID)

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
        XCTAssertEqual(remote.invocations, [.loadMediaLibraryFromWordPressSite(siteID: sampleSiteID)])

        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unauthorized)
    }

    // MARK: test cases for `MediaAction.uploadMedia`

    func test_uploadMedia_returns_uploaded_media_and_deletes_input_media_file() throws {
        // Given
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager)

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
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager)

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

    /// Verifies that `MediaAction.uploadMedia` invokes `MediaRemoteProtocol.uploadMedia` when there is no corresponding site in storage.
    func test_uploadMedia_without_storage_site_invokes_uploadMedia_remote_call() throws {
        // Given
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let remote = MockMediaRemote()
        remote.whenUploadingMedia(siteID: sampleSiteID, thenReturn: .failure(DotcomError.unauthorized))

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager, remote: remote)

        let asset = PHAsset()

        // When
        let _: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.uploadMedia(siteID: self.sampleSiteID,
                                                 productID: self.sampleProductID,
                                                 mediaAsset: asset) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.uploadMedia(siteID: sampleSiteID)])
    }

    /// Verifies that `MediaAction.uploadMedia` from a JCP site returns the uploaded media from the remote response.
    func test_uploadMedia_to_jcp_site_returns_uploaded_media_and_deletes_input_media_file() throws {
        // Given
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenUploadingMediaToWordPressSite(siteID: sampleSiteID, thenReturn: .success(media))

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager, remote: remote)

        let asset = PHAsset()

        insertJCPSiteToStorage(siteID: sampleSiteID)

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
        XCTAssertEqual(remote.invocations, [.uploadMediaToWordPressSite(siteID: sampleSiteID)])

        let mediaList = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaList, media.toMedia())

        // Verifies that the temporary file is removed after the media is uploaded.
        XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))
    }

    /// Verifies that `MediaAction.uploadMedia` from a JCP site returns an error from the remote response.
    func test_uploadMedia_to_jcp_site_returns_error_from_remote_response() throws {
        // Given
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let remote = MockMediaRemote()
        remote.whenUploadingMediaToWordPressSite(siteID: sampleSiteID, thenReturn: .failure(DotcomError.unauthorized))

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager, remote: remote)

        let asset = PHAsset()

        insertJCPSiteToStorage(siteID: sampleSiteID)

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
        XCTAssertEqual(remote.invocations, [.uploadMediaToWordPressSite(siteID: sampleSiteID)])

        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unauthorized)
    }
}

private extension MediaStoreTests {
    func createSampleUploadableMedia(targetURL: URL) -> UploadableMedia {
        return UploadableMedia(localURL: targetURL,
                               filename: "test.jpg",
                               mimeType: "image/jpeg")
    }

    func createMediaStoreAndExportableMedia(at targetURL: URL, fileManager: FileManager, remote: MediaRemoteProtocol? = nil) -> MediaStore {
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
        if let remote = remote {
            return MediaStore(mediaExportService: mediaExportService,
                              dispatcher: dispatcher,
                              storageManager: storageManager,
                              network: network,
                              remote: remote)
        } else {
            return MediaStore(mediaExportService: mediaExportService,
                              dispatcher: dispatcher,
                              storageManager: storageManager,
                              network: network)
        }
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.iso8601.date(from: dateString) else {
            return Date()
        }
        return date
    }

    func insertJCPSiteToStorage(siteID: Int64) {
        // JCP site determination requires a `Site` in storage.
        let jcpSite = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        storageManager.insertSampleSite(readOnlySite: jcpSite)
    }
}
