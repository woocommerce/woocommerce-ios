import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// NotificationStore Unit Tests
///
class NotificationStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork(useResponseQueue: true)
    }


    // MARK: - NotificationAction.synchronizeNotifications

    /// Verifies that `NotificationAction.synchronizeNotifications` effectively persists any retrieved Notes.
    ///
    func testRetrieveNotesEffectivelyPersistsRetrievedNotes() {
        let expectation = self.expectation(description: "Sync notifications")
        let notificationStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        let action = NotificationAction.synchronizeNotifications() { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 2)

            if let note = self.viewStorage.loadNotification(noteID: 99998888, noteHash: 987654)?.toReadOnly() {
                // Plain Fields
                XCTAssertEqual(note.noteId, 99998888)
                XCTAssertEqual(note.hash, 987654)
                XCTAssertEqual(note.read, false)
                XCTAssertEqual(note.icon,"https://s.wp.com/wp-content/mu-plugins/achievements/likeable-blog-5-2x.png")
                XCTAssertEqual(note.noticon, "\u{f806}")
                XCTAssertEqual(note.timestamp, "2018-10-10T01:52:46+00:00")
                XCTAssertEqual(note.type, "like_milestone_achievement")
                XCTAssertEqual(note.kind, .unknown)
                XCTAssertEqual(note.url, "http://someurl.sometld")
                XCTAssertEqual(note.title, "5 Likes")

                // Blocks
                XCTAssertEqual(note.subject.count, 1)
                XCTAssertEqual(note.header.count, 2)
                XCTAssertEqual(note.body.count, 2)

                // Meta
                XCTAssertEqual(note.meta.identifier(forKey: .site), 123456)
                XCTAssertEqual(note.meta.link(forKey: .site), "https://public-someurl.sometld")
                XCTAssertEqual(note.meta.identifier(forKey: .post), 12536)
                XCTAssertEqual(note.meta.link(forKey: .post), "https://public-someurl2.sometld")
                XCTAssertEqual(note.meta.identifier(forKey: .comment), 5168)
                XCTAssertEqual(note.meta.link(forKey: .comment), "https://public-someurl3.sometld")
                XCTAssertEqual(note.meta.identifier(forKey: .user), 1234567)
                XCTAssertEqual(note.meta.link(forKey: .user), "https://public-someurl4.sometld")
            } else {
                XCTFail()
            }

            expectation.fulfill()
        }

        notificationStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
