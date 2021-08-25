import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage

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

    /// Verifies that `AnnouncementsAction.synchronizeAnnouncements` effectively  retrieves latest Announcement
    ///
    func test_synchronize_announcements_effectively_retrieves_latest_announcement() throws {
        // Arrange
        let feature = Feature(title: "foo",
                              subtitle: "bar",
                              iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
        let announcement = Announcement(appVersion: "1", features: [feature])
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success(announcement))

        // Act
        let fetchedAnnouncement: Announcement? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { announcement in
                promise(announcement)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(fetchedAnnouncement?.appVersion, "1")
        XCTAssertEqual(fetchedAnnouncement?.features.first?.title, feature.title)
        XCTAssertEqual(fetchedAnnouncement?.features.first?.subtitle, feature.subtitle)
        XCTAssertEqual(fetchedAnnouncement?.features.first?.iconUrl, feature.iconUrl)
        XCTAssertEqual(remote.requestedAppId, "4")
    }

    func test_synchronize_announcements_with_error_gets_no_announcement() {
        // Arrange
        let error = NSError(domain: "", code: 0, userInfo: nil)
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .failure(error))

        // Act
        let announcement: Announcement? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { announcement in
                promise(announcement)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertNil(announcement)
    }
}
