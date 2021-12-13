import XCTest
@testable import Networking

final class MediaRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

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
    func test_loadMediaLibrary_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library")

        // When
        let result = waitFor { promise in
            remote.loadMediaLibrary(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 5)
    }

    /// Verifies that `loadMediaLibrary` properly relays Networking Layer errors.
    ///
    func test_loadMediaLibrary_properly_relays_networking_errors() {
        // Given
        let remote = MediaRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.loadMediaLibrary(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Load Media From Media Library `loadMediaLibrary` via WordPress Site API

    /// Verifies that `loadMediaLibraryFromWordPressSite` properly parses the `media-library-from-wordpress-site` sample response.
    ///
    func test_loadMediaLibraryFromWordPressSite_properly_returns_parsed_media_list() throws {
        // Given
        let remote = MediaRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library-from-wordpress-site")

        // When
        let result = waitFor { promise in
            remote.loadMediaLibraryFromWordPressSite(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 2)
        let uploadedMedia = try XCTUnwrap(mediaItems.first)
        XCTAssertEqual(uploadedMedia.mediaID, 22)
        XCTAssertEqual(uploadedMedia.date, Date(timeIntervalSince1970: 1637546157))
        XCTAssertEqual(uploadedMedia.slug, "img_0111-2")
        XCTAssertEqual(uploadedMedia.mimeType, "image/jpeg")
        XCTAssertEqual(uploadedMedia.src, "https://ninja.media/wp-content/uploads/2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(uploadedMedia.alt, "Floral")
        XCTAssertEqual(uploadedMedia.details?.width, 2560)
        XCTAssertEqual(uploadedMedia.details?.height, 1920)
        XCTAssertEqual(uploadedMedia.details?.fileName, "2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(uploadedMedia.title, .init(rendered: "img_0111-2"))
        XCTAssertEqual(uploadedMedia.details?.sizes["thumbnail"],
                       .init(fileName: "img_0111-2-150x150.jpeg",
                             src: "https://ninja.media/wp-content/uploads/2021/11/img_0111-2-150x150.jpeg",
                             width: 150,
                             height: 150))
    }

    /// Verifies that `loadMediaLibraryFromWordPressSite` properly relays Networking Layer errors.
    ///
    func test_loadMediaLibraryFromWordPressSite_properly_relays_networking_errors() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.loadMediaLibraryFromWordPressSite(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - uploadMedia

    /// Verifies that `uploadMedia` properly parses the `media-upload` sample response.
    ///
    func test_uploadMedia_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        let path = "sites/\(sampleSiteID)/media/new"
        network.simulateResponse(requestUrlSuffix: path, filename: "media-upload")

        // When
        let result = waitFor { promise in
            remote.uploadMedia(for: self.sampleSiteID,
                                  productID: self.sampleProductID,
                                  mediaItems: []) { result in
                promise(result)
            }
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 1)
    }

    /// Verifies that `uploadMedia` properly relays Networking Layer errors.
    ///
    func test_uploadMedia_properly_relays_networking_errors() {
        // Given
        let remote = MediaRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.uploadMedia(for: self.sampleSiteID,
                                  productID: self.sampleProductID,
                                  mediaItems: []) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    /// Verifies that `uploadMediaToWordPressSite` properly parses the `media-upload-to-wordpress-site` sample response.
    ///
    func test_uploadMediaToWordPressSite_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        let path = "sites/\(sampleSiteID)/media"
        network.simulateResponse(requestUrlSuffix: path, filename: "media-upload-to-wordpress-site")

        // When
        let result = waitFor { promise in
            remote.uploadMediaToWordPressSite(siteID: self.sampleSiteID,
                                              productID: self.sampleProductID,
                                              mediaItems: []) { result in
                promise(result)
            }
        }

        // Then
        let uploadedMedia = try XCTUnwrap(result.get())
        XCTAssertEqual(uploadedMedia.mediaID, 23)
        XCTAssertEqual(uploadedMedia.date, Date(timeIntervalSince1970: 1637477423))
        XCTAssertEqual(uploadedMedia.slug, "img_0005-1")
        XCTAssertEqual(uploadedMedia.mimeType, "image/jpeg")
        XCTAssertEqual(uploadedMedia.src, "https://ninja.media/wp-content/uploads/2021/11/img_0005-1-scaled.jpeg")
        XCTAssertEqual(uploadedMedia.alt, "Floral")
        XCTAssertEqual(uploadedMedia.details?.width, 2560)
        XCTAssertEqual(uploadedMedia.details?.height, 1708)
        XCTAssertEqual(uploadedMedia.details?.fileName, "2021/11/img_0005-1-scaled.jpeg")
        XCTAssertEqual(uploadedMedia.title, .init(rendered: "img_0005-1"))
        XCTAssertEqual(uploadedMedia.details?.sizes["thumbnail"],
                       .init(fileName: "img_0005-1-150x150.jpeg",
                             src: "https://ninja.media/wp-content/uploads/2021/11/img_0005-1-150x150.jpeg",
                             width: 150,
                             height: 150))
    }

    /// Verifies that `uploadMediaToWordPressSite` properly relays Networking Layer errors.
    ///
    func test_uploadMediaToWordPressSite_properly_relays_networking_errors() {
        // Given
        let remote = MediaRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.uploadMediaToWordPressSite(siteID: self.sampleSiteID,
                                              productID: self.sampleProductID,
                                              mediaItems: []) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
