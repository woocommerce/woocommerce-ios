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
}
