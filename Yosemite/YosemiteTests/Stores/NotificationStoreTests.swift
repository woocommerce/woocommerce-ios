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
        network = MockupNetwork()
    }


    // MARK: - NotificationAction.synchronizeNotifications

    /// Verifies that `NotificationAction.synchronizeNotifications` effectively persists any retrieved Notes.
    ///
    func testRetrieveNotesEffectivelyPersistsRetrievedNotes() {
        let expectation = self.expectation(description: "Sync notifications")
        let notificationStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // FIXME: Need a way to "stack" responses to the same endpoint
        //network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-hashes")
        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        let action = NotificationAction.synchronizeNotifications() { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 40)
            expectation.fulfill()
        }

        notificationStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
