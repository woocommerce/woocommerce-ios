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

    /// Dummy Media ID
    ///
    private let sampleMediaID: Int64 = 2352

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load Media using site ID and media ID

    /// Verifies that `loadMedia` properly parses the `media` sample response.
    ///
    func test_loadMedia_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        let mediaID: Int64 = 22
        network.simulateResponse(requestUrlSuffix: "media/\(mediaID)", filename: "media")

        // When
        let result = waitFor { promise in
            remote.loadMedia(siteID: self.sampleSiteID, mediaID: mediaID) { result in
                promise(result)
            }
        }

        // Then
        let imageMedia = try XCTUnwrap(result.get())
        XCTAssertEqual(imageMedia.mediaID, mediaID)
        XCTAssertEqual(imageMedia.date, Date(timeIntervalSince1970: 1637546157))
        XCTAssertEqual(imageMedia.slug, "img_0111-2")
        XCTAssertEqual(imageMedia.mimeType, "image/jpeg")
        XCTAssertEqual(imageMedia.src, "https://ninja.media/wp-content/uploads/2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(imageMedia.alt, "Floral")
        XCTAssertEqual(imageMedia.details?.width, 2560)
        XCTAssertEqual(imageMedia.details?.height, 1920)
        XCTAssertEqual(imageMedia.details?.fileName, "2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(imageMedia.title, .init(rendered: "img_0111-2"))
        XCTAssertEqual(imageMedia.details?.sizes?["thumbnail"],
                       .init(fileName: "img_0111-2-150x150.jpeg",
                             src: "https://ninja.media/wp-content/uploads/2021/11/img_0111-2-150x150.jpeg",
                             width: 150,
                             height: 150))
    }

    /// Verifies that `loadMedia` properly relays Networking Layer errors.
    ///
    func test_loadMedia_properly_relays_networking_errors() throws {
        // Given
        let remote = MediaRemote(network: network)
        let mediaID: Int64 = 22
        network.simulateError(requestUrlSuffix: "media/\(mediaID)", error: NetworkError.notFound(response: nil))

        // When
        let result = waitFor { promise in
            remote.loadMedia(siteID: self.sampleSiteID, mediaID: mediaID) { result in
                promise(result)
            }
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .notFound())
    }

    // MARK: - Load Media From Media Library `loadMediaLibrary`

    func test_loadMediaLibrary_sends_mime_type_filter_if_imagesOnly_is_true() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.loadMediaLibrary(for: self.sampleSiteID, imagesOnly: true, completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let mimeTypeValue = try XCTUnwrap(request.parameters?["mime_type"] as? String)
        XCTAssertEqual(mimeTypeValue, "image")
    }

    func test_loadMediaLibrary_does_not_send_mime_type_filter_if_imagesOnly_is_false() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.loadMediaLibrary(for: self.sampleSiteID, imagesOnly: false, completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        XCTAssertNil(request.parameters?["mime_type"])
    }

    /// Verifies that `loadMediaLibrary` properly parses the `media-library` sample response.
    ///
    func test_loadMediaLibrary_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "media", filename: "media-library")

        // When
        let result = waitFor { promise in
            remote.loadMediaLibrary(for: self.sampleSiteID, imagesOnly: true) { result in
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
            remote.loadMediaLibrary(for: self.sampleSiteID, imagesOnly: true) { result in
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
            remote.loadMediaLibraryFromWordPressSite(siteID: self.sampleSiteID, imagesOnly: true) { result in
                promise(result)
            }
        }

        // Then
        let mediaItems = try XCTUnwrap(result.get())
        XCTAssertEqual(mediaItems.count, 3)
        let textMedia = mediaItems[0]
        XCTAssertEqual(textMedia.mediaID, 28)
        XCTAssertEqual(textMedia.slug, "xanh-3")
        XCTAssertEqual(textMedia.mimeType, "text/plain")
        XCTAssertEqual(textMedia.title?.rendered, "Xanh-3")
        XCTAssertEqual(textMedia.src, "https://ninja.media/wp-content/uploads/2023/12/Xanh-3.txt")

        let imageMedia = mediaItems[1]
        XCTAssertEqual(imageMedia.mediaID, 22)
        XCTAssertEqual(imageMedia.date, Date(timeIntervalSince1970: 1637546157))
        XCTAssertEqual(imageMedia.slug, "img_0111-2")
        XCTAssertEqual(imageMedia.mimeType, "image/jpeg")
        XCTAssertEqual(imageMedia.src, "https://ninja.media/wp-content/uploads/2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(imageMedia.alt, "Floral")
        XCTAssertEqual(imageMedia.details?.width, 2560)
        XCTAssertEqual(imageMedia.details?.height, 1920)
        XCTAssertEqual(imageMedia.details?.fileName, "2021/11/img_0111-2-scaled.jpeg")
        XCTAssertEqual(imageMedia.title, .init(rendered: "img_0111-2"))
        XCTAssertEqual(imageMedia.details?.sizes?["thumbnail"],
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
            remote.loadMediaLibraryFromWordPressSite(siteID: self.sampleSiteID, imagesOnly: true) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - uploadMedia

    func test_uploadMedia_does_not_send_data_in_request_body() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.uploadMedia(for: self.sampleSiteID, productID: sampleProductID, mediaItems: [], completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        XCTAssertNil(try request.asURLRequest().httpBody)
    }

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

    func test_uploadMediaToWordPressSite_does_not_send_data_in_request_body() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.uploadMediaToWordPressSite(siteID: sampleSiteID, productID: sampleProductID, mediaItem: .fake(), completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        XCTAssertNil(try request.asURLRequest().httpBody)
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
                                              mediaItem: .fake()) { result in
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
        XCTAssertEqual(uploadedMedia.details?.sizes?["thumbnail"],
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
                                              mediaItem: .fake()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - updateProductID

    /// Verifies that `updateProductID` properly parses the `media-update-product-id` sample response.
    ///
    func test_updateProductID_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        let path = "sites/\(sampleSiteID)/media/\(sampleMediaID)"
        network.simulateResponse(requestUrlSuffix: path, filename: "media-update-product-id")

        // When
        let result = waitFor { promise in
            remote.updateProductID(siteID: self.sampleSiteID,
                                   productID: self.sampleProductID,
                                   mediaID: self.sampleMediaID) { result in
                promise(result)
            }
        }

        // Then
        let media = try XCTUnwrap(result.get())
        XCTAssertEqual(media.mediaID, sampleMediaID)
    }

    /// Verifies that `updateProductID` properly relays Networking Layer errors.
    ///
    func test_updateProductID_properly_relays_networking_errors() {
        // Given
        let remote = MediaRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.updateProductID(siteID: self.sampleSiteID,
                                   productID: self.sampleProductID,
                                   mediaID: self.sampleMediaID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - updateProductIDToWordPressSite

    /// Verifies that `updateProductIDToWordPressSite` properly parses the `media-update-product-id-in-wordpress-site` sample response.
    ///
    func test_updateProductIDToWordPressSite_properly_returns_parsed_media() throws {
        // Given
        let remote = MediaRemote(network: network)
        let path = "sites/\(sampleSiteID)/media/\(sampleMediaID)"
        network.simulateResponse(requestUrlSuffix: path, filename: "media-update-product-id-in-wordpress-site")

        // When
        let result = waitFor { promise in
            remote.updateProductIDToWordPressSite(siteID: self.sampleSiteID,
                                   productID: self.sampleProductID,
                                   mediaID: self.sampleMediaID) { result in
                promise(result)
            }
        }

        // Then
        let media = try XCTUnwrap(result.get())
        XCTAssertEqual(media.mediaID, sampleMediaID)
    }

    /// Verifies that `updateProductIDToWordPressSite` properly relays Networking Layer errors.
    ///
    func test_updateProductIDToWordPressSite_properly_relays_networking_errors() {
        // Given
        let remote = MediaRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.updateProductIDToWordPressSite(siteID: self.sampleSiteID,
                                   productID: self.sampleProductID,
                                   mediaID: self.sampleMediaID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Loading media for specific product ID

    func test_loadMediaLibrary_sends_postID_filter_if_productID_is_not_nil() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.loadMediaLibrary(for: self.sampleSiteID,
                                productID: 32,
                                imagesOnly: true,
                                completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let postIDValue = try XCTUnwrap(request.parameters?["post_ID"] as? Int64)
        XCTAssertEqual(postIDValue, 32)
    }

    func test_loadMediaLibrary_does_not_send_postID_filter_if_productID_is_nil() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.loadMediaLibrary(for: self.sampleSiteID,
                                imagesOnly: true,
                                completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        XCTAssertNil(request.parameters?["post_ID"])
    }

    func test_loadMediaLibraryFromWordPressSite_sends_parent_filter_if_productID_is_not_nil() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.loadMediaLibraryFromWordPressSite(siteID: self.sampleSiteID,
                                                 productID: 32,
                                                 imagesOnly: true,
                                                 completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        let postIDValue = try XCTUnwrap(request.parameters?["parent"] as? Int64)
        XCTAssertEqual(postIDValue, 32)
    }

    func test_loadMediaLibraryFromWordPressSite_does_not_send_parent_filter_if_productID_is_nil() throws {
        // Given
        let remote = MediaRemote(network: network)

        // When
        remote.loadMediaLibraryFromWordPressSite(siteID: self.sampleSiteID,
                                                 imagesOnly: true,
                                                 completion: { _ in })

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.last as? DotcomRequest)
        XCTAssertNil(request.parameters?["parent"])
    }
}
