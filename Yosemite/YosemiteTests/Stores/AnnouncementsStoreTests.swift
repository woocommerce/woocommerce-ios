import XCTest
import WordPressKit
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

    func test_synchronize_announcements_effectively_retrieves_latest_announcement() throws {
        // Arrange
        let announcement = try XCTUnwrap(self.makeWordPressAnnouncement())
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success([announcement]))

        // Act
        let fetchedAnnouncement: StorageAnnouncement? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { result in
                promise(try? result.get())
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(fetchedAnnouncement?.appVersion, "1")
        XCTAssertEqual(fetchedAnnouncement?.announcementVersion, "2")
        XCTAssertEqual(fetchedAnnouncement?.features.first?.title, "foo")
        XCTAssertEqual(fetchedAnnouncement?.features.first?.subtitle, "bar")
        XCTAssertEqual(fetchedAnnouncement?.features.first?.iconUrl, "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
        XCTAssertEqual(remote.requestedAppId, "4")
    }

    func test_synchronize_announcements_with_empty_response_error_gets_an_error() {
        // Arrange
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success([]))

        // Act
        let resultError: AnnouncementsError? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { result in
                promise(result.failure as? AnnouncementsError)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(resultError, .unableToGetAnnouncement)
    }

    func test_synchronize_announcements_with_error_gets_an_error() {
        // Arrange
        let error = NSError(domain: "", code: 0, userInfo: nil)
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .failure(error))

        // Act
        let resultError: AnnouncementsError? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { result in
                promise(result.failure as? AnnouncementsError)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(resultError, .unableToGetAnnouncement)
    }
}

// MARK: - Mocks
//
private extension AnnouncementsStoreTests {
    func makeWordPressAnnouncement() throws -> WordPressKit.Announcement {
        let announcementJson: [String: Any] = [
            "appVersionName": "1",
            "minimumAppVersion": "",
            "maximumAppVersion": "",
            "appVersionTargets": [],
            "detailsUrl": "http://wordpress.org",
            "features": [[
                "title": "foo",
                "subtitle": "bar",
                "iconBase64": "",
                "iconUrl": "https://s0.wordpress.com/i/store/mobile/plans-premium.png"
            ]],
            "announcementVersion": "2",
            "isLocalized": true,
            "responseLocale": "en_US"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: announcementJson)
        return try JSONDecoder().decode(WordPressKit.Announcement.self, from: jsonData)
    }
}
