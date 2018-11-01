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

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-hashes")
        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        let action = NotificationAction.synchronizeNotifications() { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 40)

            if let note = self.viewStorage.loadNotification(noteID: 123456, noteHash: 987654)?.toReadOnly() {
                // Plain Fields
                XCTAssertEqual(note.noteId, 123456)
                XCTAssertEqual(note.hash, 987654)
                XCTAssertEqual(note.read, false)
                XCTAssert(note.icon == "https://gravatar.tld/some-hash")
                XCTAssert(note.noticon == "\u{f408}")
                XCTAssertEqual(note.timestamp, "2018-10-22T18:51:33+00:00")
                XCTAssertEqual(note.type, "comment_like")
                XCTAssertEqual(note.kind, .commentLike)
                XCTAssert(note.url == "https://someurl.sometld")
                XCTAssert(note.title == "3 Likes")

                // Blocks
                XCTAssertEqual(note.subject.count, 1)
                XCTAssertEqual(note.header.count, 2)
                XCTAssertEqual(note.body.count, 3)

                // Meta
                XCTAssertEqual(note.meta.identifier(forKey: .site), 123456)
                XCTAssertEqual(note.meta.identifier(forKey: .post), 2996)
                XCTAssertEqual(note.meta.link(forKey: .post), "https://public-someurl.sometld")
            } else {
                XCTFail()
            }

            expectation.fulfill()
        }

        notificationStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
