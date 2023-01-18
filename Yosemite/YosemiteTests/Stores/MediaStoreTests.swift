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

    /// Testing Site URL
    ///
    private let sampleSiteURL = "http://test.com"

    /// Testing Product ID
    ///
    private let sampleProductID: Int64 = 586

    /// Testing Media ID
    ///
    private let sampleMediaID: Int64 = 2352

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: test cases for `MediaAction.retrieveMediaLibrary`

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns the expected response when using WPCOM siteID.
    ///
    func test_retrieveMediaLibrary_returns_media_list_when_connect_using_siteID() throws {
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
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
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

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns the expected response when using site URL.
    ///
    func test_retrieveMediaLibrary_returns_media_list_when_connect_using_siteURL() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library-from-wordpress-site")
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wporg(self.sampleSiteURL),
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 2)
        let uploadedMedia = try XCTUnwrap(mediaItems.first)
        XCTAssertEqual(uploadedMedia.mediaID, 22)
        XCTAssertEqual(uploadedMedia.date, Date(timeIntervalSince1970: 1637546157))
        XCTAssertEqual(uploadedMedia.mimeType, "image/jpeg")
        XCTAssertEqual(uploadedMedia.src, "https://ninja.media/wp-content/uploads/2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(uploadedMedia.alt, "Floral")
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
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
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
    func test_retrieveMediaLibrary_returns_error_upon_response_error_when_connect_using_siteID() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "media", filename: "generic_error")
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
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

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is an error response from the backend.
    ///
    func test_retrieveMediaLibrary_returns_error_upon_response_error_when_connect_using_siteURL() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "media", filename: "rest_incorrect_application_password_error")
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wporg(self.sampleSiteURL),
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? WordPressApiError)
        XCTAssertEqual(error, .unknown(code: "incorrect_password", message: "The provided password is an invalid application password."))
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is no backend response.
    ///
    func test_retrieveMediaLibrary_returns_error_upon_empty_response_when_connect_using_siteID() {
        // Given
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)
        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` returns an error whenever there is no backend response.
    ///
    func test_retrieveMediaLibrary_returns_error_upon_empty_response_when_connect_using_siteURL() {
        // Given
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network)
        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wporg(self.sampleSiteURL),
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
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadMediaLibrary(siteID: sampleSiteID)])
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` for a placeholder site ID returns the media list from the remote response.
    func test_retrieveMediaLibrary_returns_media_list_when_connecting_to_site_with_placeholder_site_id() throws {
        // Given
        let siteID = WooConstants.placeholderSiteID
        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenLoadingMediaLibraryFromWordPressSite(siteID: siteID, thenReturn: .success([media]))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        insertJCPSiteToStorage(siteID: sampleSiteID)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(siteID: siteID,
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadMediaLibraryFromWordPressSite(siteID: siteID)])

        let mediaList = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaList, [media.toMedia()])
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` for a placeholder site ID returns the media list from the remote response.
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
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
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
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wpcom(self.sampleSiteID),
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

    /// Verifies that `MediaAction.retrieveMediaLibrary` invokes `MediaRemoteProtocol.loadMediaLibraryUsingRestApi` when connect using site URL.
    func test_retrieveMediaLibrary_invokes_loadMediaLibraryUsingRestApi_remote_call_when_connect_using_site_URL() throws {
        // Given
        let remote = MockMediaRemote()
        remote.whenLoadingMediaLibraryUsingRestApi(siteURL: sampleSiteURL, thenReturn: .success([]))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        // When
        let _: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wporg(self.sampleSiteURL),
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadMediaLibraryUsingRestApi(siteURL: sampleSiteURL)])
    }

    /// Verifies that `MediaAction.retrieveMediaLibrary` using site URL returns error from remote
    func test_retrieveMediaLibrary_using_site_URL_returns_error_from_MediaRemote() throws {
        // Given
        let expectedError = WordPressApiError.unknown(code: "1", message: "Sample message")
        let remote = MockMediaRemote()
        remote.whenLoadingMediaLibraryUsingRestApi(siteURL: sampleSiteURL, thenReturn: .failure(expectedError))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        insertJCPSiteToStorage(siteID: sampleSiteID)

        // When
        let result: Result<[Media], Error> = waitFor { promise in
            let action = MediaAction.retrieveMediaLibrary(connectUsing: .wporg(self.sampleSiteURL),
                                                          pageNumber: 1,
                                                          pageSize: 20) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.loadMediaLibraryUsingRestApi(siteURL: sampleSiteURL)])

        let error = try XCTUnwrap(result.failure as? WordPressApiError)
        XCTAssertEqual(error, expectedError)
    }

    // MARK: test cases for `MediaAction.uploadMedia`

    func test_uploadMedia_returns_uploaded_media_and_deletes_input_media_file_when_connect_using_siteID() throws {
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
            let action = MediaAction.uploadMedia(connectUsing: .wpcom(self.sampleSiteID),
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

    func test_uploadMedia_returns_uploaded_media_and_deletes_input_media_file_when_connect_using_siteURL() throws {
        // Given
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager)

        let path = "media"
        network.simulateResponse(requestUrlSuffix: path, filename: "media-upload-to-wordpress-site")

        let asset = PHAsset()

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.uploadMedia(connectUsing: .wporg(self.sampleSiteURL),
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

    func test_uploadMedia_returns_error_upon_response_error_when_connect_using_siteID() {
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
            let action = MediaAction.uploadMedia(connectUsing: .wpcom(self.sampleSiteID),
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

    func test_uploadMedia_returns_error_upon_response_error_when_connect_using_siteURL() {
        // Given
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager)

        let path = "media"

        network.simulateResponse(requestUrlSuffix: path, filename: "rest_incorrect_application_password_error")

        let asset = PHAsset()

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.uploadMedia(connectUsing: .wporg(self.sampleSiteURL),
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
            let action = MediaAction.uploadMedia(connectUsing: .wpcom(self.sampleSiteID),
                                                 productID: self.sampleProductID,
                                                 mediaAsset: asset) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.uploadMedia(siteID: sampleSiteID)])
    }

    /// Verifies that `MediaAction.uploadMedia` for a placeholder site ID returns the uploaded media from the remote response.
    func test_uploadMediareturns_uploaded_media_and_deletes_input_media_file_when_connecting_to_site_with_placeholder_site_id() throws {
        // Given
        let siteID = WooConstants.placeholderSiteID
        let fileManager = FileManager.default

        // Creates a temporary file to simulate a uploadable media file.
        let targetURL: URL = {
            let filename = "test.txt"
            return fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
        }()

        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenUploadingMediaToWordPressSite(siteID: siteID, thenReturn: .success(media))

        let mediaStore = createMediaStoreAndExportableMedia(at: targetURL, fileManager: fileManager, remote: remote)

        let asset = PHAsset()

        insertJCPSiteToStorage(siteID: siteID)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.uploadMedia(siteID: siteID,
                                                 productID: self.sampleProductID,
                                                 mediaAsset: asset) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        XCTAssertEqual(remote.invocations, [.uploadMediaToWordPressSite(siteID: siteID)])

        let mediaList = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaList, media.toMedia())

        // Verifies that the temporary file is removed after the media is uploaded.
        XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))
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
            let action = MediaAction.uploadMedia(connectUsing: .wpcom(self.sampleSiteID),
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
            let action = MediaAction.uploadMedia(connectUsing: .wpcom(self.sampleSiteID),
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

    // MARK: test cases for `MediaAction.updateProductID`

    /// Verifies that `MediaAction.updateProductID` returns the expected response.
    ///
    func test_updateProductID_returns_media() throws {
        // Given
        let remote = MockMediaRemote()
        let media = Media.fake()
        remote.whenUpdatingProductID(siteID: sampleSiteID, thenReturn: .success(media))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)
        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(connectUsing: .wpcom(self.sampleSiteID),
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaFromResult = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaFromResult, media)
    }

    /// Verifies that `MediaAction.updateProductID` returns an error whenever there is an error response from the backend.
    ///
    func test_updateProductID_returns_error_upon_response_error() throws {
        // Given
        let remote = MockMediaRemote()
        remote.whenUpdatingProductID(siteID: sampleSiteID, thenReturn: .failure(DotcomError.unauthorized))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(connectUsing: .wpcom(self.sampleSiteID),
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unauthorized)
    }

    /// Verifies that `MediaAction.updateProductID` returns the expected response while connecting to site with placeholder site ID.
    ///
    func test_updateProductID_returns_media_when_connecting_to_site_with_placeholder_site_id() throws {
        // Given
        let siteID = WooConstants.placeholderSiteID
        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenUpdatingProductIDToWordPressSite(siteID: siteID, thenReturn: .success(media))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)
        insertJCPSiteToStorage(siteID: siteID)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(siteID: siteID,
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaFromResult = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaFromResult, media.toMedia())
    }

    /// Verifies that `MediaAction.updateProductID` returns the expected response while connecting to JCP sites.
    ///
    func test_updateProductIDToWordPressSite_returns_media() throws {
        // Given
        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenUpdatingProductIDToWordPressSite(siteID: sampleSiteID, thenReturn: .success(media))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)
        insertJCPSiteToStorage(siteID: sampleSiteID)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(connectUsing: .wpcom(self.sampleSiteID),
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaFromResult = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaFromResult, media.toMedia())
    }

    /// Verifies that `MediaAction.updateProductID` while connecting to JCP sites returns an error whenever there is an error response from the backend.
    ///
    func test_updateProductIDToWordPressSite_returns_error_upon_response_error() throws {
        // Given
        let remote = MockMediaRemote()
        remote.whenUpdatingProductIDToWordPressSite(siteID: sampleSiteID, thenReturn: .failure(DotcomError.unauthorized))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)
        insertJCPSiteToStorage(siteID: sampleSiteID)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(connectUsing: .wpcom(self.sampleSiteID),
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? DotcomError)
        XCTAssertEqual(error, .unauthorized)
    }

    /// Verifies that `MediaAction.updateProductID` returns the expected response while connecting using Site URL
    ///
    func test_updateProductID_returns_media_when_connect_using_siteURL() throws {
        // Given
        let remote = MockMediaRemote()
        let media = WordPressMedia.fake()
        remote.whenUpdatingProductIDUsingRestApi(siteURL: sampleSiteURL, thenReturn: .success(media))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(connectUsing: .wporg(self.sampleSiteURL),
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let mediaFromResult = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaFromResult, media.toMedia())
    }

    /// Verifies that `MediaAction.updateProductID`  while connecting using Site URL returns an error whenever there is an error response from the backend.
    ///
    func test_updateProductID_returns_error_upon_response_error_when_connect_using_siteURL() throws {
        // Given
        let expectedError = WordPressApiError.unknown(code: "1", message: "Sample message")
        let remote = MockMediaRemote()
        remote.whenUpdatingProductIDUsingRestApi(siteURL: sampleSiteURL, thenReturn: .failure(expectedError))
        let mediaStore = MediaStore(dispatcher: dispatcher,
                                    storageManager: storageManager,
                                    network: network,
                                    remote: remote)

        // When
        let result: Result<Media, Error> = waitFor { promise in
            let action = MediaAction.updateProductID(connectUsing: .wporg(self.sampleSiteURL),
                                                     productID: self.sampleProductID,
                                                     mediaID: self.sampleMediaID) { result in
                promise(result)
            }
            mediaStore.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure as? WordPressApiError)
        XCTAssertEqual(error, expectedError)
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
