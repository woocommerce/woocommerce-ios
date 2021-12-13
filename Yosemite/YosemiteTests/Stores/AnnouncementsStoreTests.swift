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
        let fetchedAnnouncement: WordPressKit.Announcement? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { result in
                promise(try? result.get())
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(fetchedAnnouncement?.appVersionName, "1")
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
        XCTAssertEqual(resultError, .announcementNotFound)
    }

    func test_synchronize_announcements_with_error_gets_an_error() {
        // Arrange
        let error = NSError(domain: "", code: 0, userInfo: nil)
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .failure(error))

        // Act
        let resultError: NSError? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeAnnouncements { result in
                promise(result.failure as NSError?)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(resultError, error)
    }

    func test_load_saved_announcement_without_saved_data_returns_error() {
        // Arrange, Act
        let resultError: AnnouncementsStorageError? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.loadSavedAnnouncement { result in
                promise(result.failure as? AnnouncementsStorageError)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(resultError, .invalidAnnouncement)
    }

    func test_load_newly_saved_announcement_returns_an_announcement_not_yet_displayed() throws {
        //Arrange
        try fileStorage?.write(makeStorageAnnouncement(), to: try XCTUnwrap(expectedFeatureAnnouncementsFileURL))

        // Act
        let (announcement, isDisplayed): (WordPressKit.Announcement, Bool) = waitFor { [weak self] promise in
            let action = AnnouncementsAction.loadSavedAnnouncement { result in
                promise(try! result.get())
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertNotNil(announcement)
        XCTAssertFalse(isDisplayed)
    }

    func test_load_saved_announcement_already_displayed_returns_a_displayed_announcement() throws {
        //Arrange
        try fileStorage?.write(makeStorageAnnouncement(displayed: true), to: try XCTUnwrap(expectedFeatureAnnouncementsFileURL))

        // Act
        let (announcement, isDisplayed): (WordPressKit.Announcement, Bool) = waitFor { [weak self] promise in
            let action = AnnouncementsAction.loadSavedAnnouncement { result in
                promise(try! result.get())
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertNotNil(announcement)
        XCTAssertTrue(isDisplayed)
    }

    func test_on_mark_announcement_as_displayed_it_updates_storage_model() throws {
        //Arrange
        try fileStorage?.write(makeStorageAnnouncement(displayed: false), to: try XCTUnwrap(expectedFeatureAnnouncementsFileURL))

        // Act
        let error: Error? = waitFor { [weak self] promise in
            let action = AnnouncementsAction.markSavedAnnouncementAsDisplayed { result in
                promise(result.failure)
            }
            self?.subject?.onAction(action)
        }

        let (announcement, isDisplayed): (WordPressKit.Announcement, Bool) = waitFor { [weak self] promise in
            let action = AnnouncementsAction.loadSavedAnnouncement { result in
                promise(try! result.get())
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertNil(error)
        XCTAssertNotNil(announcement)
        XCTAssertTrue(isDisplayed)
    }
}

// MARK: - Utils
//
private extension AnnouncementsStoreTests {
    var expectedFeatureAnnouncementsFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("feature-announcements.plist")
    }

    func makeWordPressAnnouncement() throws -> WordPressKit.Announcement {
        let jsonData = try JSONSerialization.data(withJSONObject: [
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
        ])

        return try JSONDecoder().decode(Announcement.self, from: jsonData)
    }

    func makeStorageAnnouncement(displayed: Bool = false) -> StorageAnnouncement {
        StorageAnnouncement(appVersionName: "1",
                            minimumAppVersion: "1",
                            maximumAppVersion: "2",
                            appVersionTargets: [],
                            detailsUrl: "",
                            announcementVersion: "",
                            isLocalized: true,
                            responseLocale: "",
                            features: [],
                            displayed: displayed)
    }
}
