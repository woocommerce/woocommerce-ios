import XCTest
import WordPressKit
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

    /// Test subject
    ///
    private var subject: AnnouncementsStore?

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockAnnouncementsRemote()

        subject = AnnouncementsStore(dispatcher: dispatcher,
                                     storageManager: storageManager,
                                     network: network,
                                     remote: remote)
    }

    /// Verifies that `AnnouncementsAction.synchronizeFeatures` effectively  retrieves new Features
    ///
    func test_synchronize_features_effectively_retrieves_features() throws {
        // Arrange
        remote.whenLoadingAnnouncements(for: UserAgent.bundleShortVersion, thenReturn: .success(try self.makeAnnouncements()))

        // Act
        let features: [Feature] = waitFor { [weak self] promise in
            let action = AnnouncementsAction.synchronizeFeatures { features in
                promise(features)
            }
            self?.subject?.onAction(action)
        }

        // Assert
        XCTAssertEqual(features.count, 1)
        XCTAssertEqual(features.first?.title, "foo")
        XCTAssertEqual(features.first?.subtitle, "bar")
        XCTAssertEqual(features.first?.iconUrl, "https://s0.wordpress.com/i/store/mobile/plans-premium.png")
    }
}

// MARK: - Response Mocks
private extension AnnouncementsStoreTests {
    func makeAnnouncements(from filename: String = TestConstants.announcementsJSONResponseFileName) throws -> [Announcement] {
        let announcementsData = try XCTUnwrap(Loader.contentsOf(filename))
        return try JSONDecoder().decode([Announcement].self, from: announcementsData)
    }
}
