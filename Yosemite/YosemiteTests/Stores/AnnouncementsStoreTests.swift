import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

/// Mock constants
///
private struct TestConstants {
    static let announcementsJSONResponseFileName = "feature-announcements"
}

final class AnnouncementsStoreTests: XCTestCase {
    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Remote: Allows us to inject predefined Announcements
    ///
    private var remote: MockAnnouncementsRemote!

    /// Mock File Storage: Load a plist in the test bundle
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AnnouncementsStore?

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockAnnouncementsRemote()
        fileStorage = MockInMemoryStorage()

        subject = AnnouncementsStore(dispatcher: dispatcher,
                                     storageManager: storageManager,
                                     network: network,
                                     remote: remote,
                                     fileStorage: fileStorage)
    }

    /// Verifies that `AnnouncementsAction.synchronizeFeatures` effectively  retrieves new Features
    ///
    func test_synchronize_features_effectively_retrieves_features() throws {
        // Arrange
        let feature = WooCommerceFeature(title: "foo",
                                         subtitle: "bar",
                                         iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success([feature]))

        // Act
        let features: [WooCommerceFeature] = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeFeatures { features, _ in
                promise(features)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(features.count, 1)
        XCTAssertEqual(features.first?.title, feature.title)
        XCTAssertEqual(features.first?.subtitle, feature.subtitle)
        XCTAssertEqual(features.first?.iconUrl, feature.iconUrl)
        XCTAssertEqual(remote.requestedAppId, "4")
    }

    func test_synchronize_features_with_result_doesnt_fetch_announcements_twice_for_the_same_version() throws {
        // Arrange
        let feature = WooCommerceFeature(title: "", subtitle: "", iconUrl: "")
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success([feature]))

        // Act
        let isCached: Bool = waitFor { [self] promise in
            self.subject?.onAction(AnnouncementsAction.synchronizeFeatures { [weak self] _, _ in
                // Second action trigger (this one must not reach out to Remote)
                self?.subject?.onAction(AnnouncementsAction.synchronizeFeatures { _, isCached in
                    promise(isCached)
                })
            })
        }

        // Assert
        XCTAssertEqual(remote.numberOfTimesGetAnnouncementsWasCalled, 1)
        XCTAssertTrue(isCached)
    }

    func test_synchronize_features_with_empty_result_can_fetch_announcements_twice_for_the_same_version() throws {
        // Arrange
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success([]))

        // Act
        let isCached: Bool = waitFor { [self] promise in
            self.subject?.onAction(AnnouncementsAction.synchronizeFeatures { [weak self] _, _ in
                // Second action trigger (this one must not reach out to Remote)
                self?.subject?.onAction(AnnouncementsAction.synchronizeFeatures { _, isCached in
                    promise(isCached)
                })
            })
        }

        // Assert
        XCTAssertEqual(remote.numberOfTimesGetAnnouncementsWasCalled, 2)
        XCTAssertFalse(isCached)
    }

    func test_synchronize_features_with_error_gets_an_empty_list_of_features() {
        // Arrange
        let error = NSError(domain: "", code: 0, userInfo: nil)
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .failure(error))

        // Act
        let features: [WooCommerceFeature] = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeFeatures { features, _ in
                promise(features)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertTrue(features.isEmpty)
    }
}
