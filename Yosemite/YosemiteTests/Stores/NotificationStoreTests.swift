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

        // Need to nuke this in-between tests otherwise some will randomly fail
        NotificationStore.resetSharedDerivedStorage()
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
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 40)

            if let note = self.viewStorage.loadNotification(noteID: 100036, noteHash: 987654)?.toReadOnly() {
                // Plain Fields
                XCTAssertEqual(note.noteId, 100036)
                XCTAssertEqual(note.hash, 987654)
                XCTAssertEqual(note.read, false)
                XCTAssertEqual(note.icon, "https://s.wp.com/wp-content/mu-plugins/achievements/likeable-blog-5-2x.png")
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

    /// Verifies that `NotificationAction.synchronizeNotifications` will only request the notifications that aren't locally
    /// stored, and are up to date.
    ///
    func testSynchronizeNotificationsRequestsOnlyOutdatedNotes() {
        let expectation = self.expectation(description: "Sync notifications")
        let notificationStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)

        /// Secondary Sync:
        /// This call is expected to just request the Hashes, and not to perform a 4th network call (because everything
        /// will be up to date. Supposedly.)
        ///
        let nestedSyncAction = NotificationAction.synchronizeNotifications() { (error) in
            XCTAssertEqual(self.network.requestsForResponseData.count, 3)
            expectation.fulfill()
        }

        /// Initial Sync
        ///
        let initialSyncAction = NotificationAction.synchronizeNotifications() { (error) in
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 40)
            notificationStore.onAction(nestedSyncAction)
        }

        notificationStore.onAction(initialSyncAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `NotificationAction.synchronizeNotification` will effectively request a single notification,
    /// which will be stored in CoreData.
    ///
    func testSynchronizeSingleNotificationEffectivelyUpdatesRequestedNote() {
        let expectation = self.expectation(description: "Sync notification")
        let notificationStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let notificationId = Int64(100001)

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)

        let syncAction = NotificationAction.synchronizeNotification(noteId: notificationId) { note, error  in
            let note = self.viewStorage.loadNotification(noteID: notificationId)
            XCTAssertNil(error)
            XCTAssertNotNil(note)

            let request = self.network.requestsForResponseData[0] as! DotcomRequest
            XCTAssertEqual(request.parameters?["ids"] as? String, String(notificationId))

            expectation.fulfill()
        }

        notificationStore.onAction(syncAction)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - NotificationAction.updateLastSeen

    /// Verifies that NotificationAction.updateLastSeen handles a success response from the backend properly
    ///
    func testUpdateLastSeenReturnsSuccess() {
        let expectation = self.expectation(description: "Update last seen success response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "notifications/seen", filename: "generic_success")
        let action = NotificationAction.updateLastSeen(timestamp: "2018-11-05T16:03:15+00:00") { (error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that NotificationAction.updateLastSeen returns an error whenever there is an error response from the backend.
    ///
    func testUpdateLastSeenReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Update last seen error response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "notifications/seen", filename: "generic_error")
        let action = NotificationAction.updateLastSeen(timestamp: "2018-11-05T16:03:15+00:00") { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that NotificationAction.updateLastSeen returns an error whenever there is no backend response.
    ///
    func testUpdateLastSeenReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Update last seen empty response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = NotificationAction.updateLastSeen(timestamp: "2018-11-05T16:03:15+00:00") { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - NotificationAction.updateReadStatus

    /// Verifies that NotificationAction.updateReadStatus handles a success response from the backend properly
    ///
    func testUpdateNotificationReadStatusReturnsSuccess() {
        let expectation = self.expectation(description: "Update read status success response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let originalNote = sampleNotification()
        let expectedNote = sampleNotificationMutated()

        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_success")
        let action = NotificationAction.updateReadStatus(noteId: originalNote.noteId, read: true) { [weak self] (error) in
            XCTAssertNil(error)
            let storageNote = self?.viewStorage.loadNotification(noteID: originalNote.noteId)
            XCTAssertEqual(storageNote?.toReadOnly().read, expectedNote.read)
            expectation.fulfill()
        }

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        noteStore.updateLocalNotes(with: [originalNote]) { [weak self] in
            XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            noteStore.onAction(action)
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that NotificationAction.updateReadStatus returns an error whenever there is an error response from the backend.
    ///
    func testUpdateNotificationReadStatusReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Update notification read status error response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_error")
        let action = NotificationAction.updateReadStatus(noteId: 9999, read: true) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that NotificationAction.updateReadStatus returns an error whenever there is no backend response.
    ///
    func testUpdateNotificationReadStatusReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Update notification read status empty response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = NotificationAction.updateReadStatus(noteId: 9999, read: true) { (error) in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `updateLocalNoteReadStatus` does not produce duplicate entries.
    ///
    func testUpdateStoredNotificationEffectivelyUpdatesPreexistantNotification() {
        let expectation = self.expectation(description: "Update read status on existing note")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let originalNote = sampleNotification()
        let expectedNote = sampleNotificationMutated()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        noteStore.updateLocalNotes(with: [originalNote]) { [weak self] in
            XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            noteStore.updateLocalNoteReadStatus(for: [originalNote.noteId], read: true) {
                XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
                let storageNote = self?.viewStorage.loadNotification(noteID: originalNote.noteId)
                XCTAssertEqual(storageNote?.toReadOnly().read, expectedNote.read)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `updateLocalNoteReadStatus` does not produce duplicate entries with an invalid notification ID.
    ///
    func testUpdateStoredNotificationDoesntUpdateInvalidNote() {
        let expectation = self.expectation(description: "Update read status on invalid note")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        noteStore.updateLocalNoteReadStatus(for: [9999], read: true) { [weak self] in
            XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 0)
            let storageNote = self?.viewStorage.loadNotification(noteID: 9999)
            XCTAssertNil(storageNote)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `NotificationAction.updateReadStatus` effectively invalidates the note's hash on error.
    ///
    func testMarkAsReadInvalidatesTheNotificationHashOnError() {
        let expectation = self.expectation(description: "Update read status success response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let originalNote = sampleNotification()

        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_error")
        let action = NotificationAction.updateReadStatus(noteId: originalNote.noteId, read: true) { [weak self] (error) in
            XCTAssertNotNil(error)

            let storageNote = self?.viewStorage.loadNotification(noteID: originalNote.noteId)
            XCTAssertEqual(storageNote?.toReadOnly().hash, Int64.min)

            expectation.fulfill()
        }

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        noteStore.updateLocalNotes(with: [originalNote]) { [weak self] in
            XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            noteStore.onAction(action)
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - NotificationAction.updateMultipleReadStatus

    /// Verifies that NotificationAction.updateMultipleReadStatus handles a success response from the backend properly
    ///
    func testUpdateMultipleNotificationReadStatusEffectivelyPatchesLocalFlags() {
        let expectation = self.expectation(description: "Update read status success response")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let originalNote = sampleNotification()
        let expectedNote = sampleNotificationMutated()

        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_success")

        // Mark as Read
        let action = NotificationAction.updateMultipleReadStatus(noteIds: [originalNote.noteId], read: true) { error in
            XCTAssertNil(error)

            let reloadedNote = self.viewStorage.loadNotification(noteID: originalNote.noteId)?.toReadOnly()
            XCTAssertEqual(reloadedNote?.read, expectedNote.read)
            expectation.fulfill()
        }

        // Insert the Note
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        noteStore.updateLocalNotes(with: [originalNote]) { [weak self] in
            XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            noteStore.onAction(action)
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - NotificationAction.registerDevice

    /// Verifies that NotificationAction.registerDevice successfully handles a success response from the backend.
    ///
    func testRegisterDeviceHandlesSuccessfulResponse() {
        let expectation = self.expectation(description: "Register Device")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "new", filename: "device-settings")

        let action = NotificationAction.registerDevice(device: sampleAPNSDevice(),
                                                       applicationId: sampleApplicationID,
                                                       applicationVersion: sampleApplicationVersion,
                                                       defaultStoreID: sampleDefaultStoreID) { (device, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(device)
            XCTAssertEqual(device?.deviceID, "12345678")

            expectation.fulfill()
        }

        noteStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that NotificationAction.registerDevice successfully handles a failure response from the backend.
    ///
    func testRegisterDeviceHandlesFailureResponse() {
        let expectation = self.expectation(description: "Register Device")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "new", filename: "generic_error")

        let action = NotificationAction.registerDevice(device: sampleAPNSDevice(),
                                                       applicationId: sampleApplicationID,
                                                       applicationVersion: sampleApplicationVersion,
                                                       defaultStoreID: sampleDefaultStoreID) { (device, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(device)

            expectation.fulfill()
        }

        noteStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - NotificationAction.unregisterDevice

    /// Verifies that NotificationAction.unregisterDevice successfully handles a success response from the backend.
    ///
    func testUnregisterDeviceHandlesSuccessfulResponse() {
        let expectation = self.expectation(description: "Unregister Device")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "delete", filename: "generic_success")

        let action = NotificationAction.unregisterDevice(deviceId: sampleDotcomDeviceID) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that NotificationAction.unregisterDevice successfully handles a failure response from the backend.
    ///
    func testUnregisterDeviceHandlesFailureResponse() {
        let expectation = self.expectation(description: "Unregister Device")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "delete", filename: "generic_error")

        let action = NotificationAction.unregisterDevice(deviceId: sampleDotcomDeviceID) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        noteStore.onAction(action)

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }


    // MARK: - NotificationAction.updateLocalDeletedStatus

    /// Verifies that `markLocalNoteAsDeleted` works as expected.
    ///
    func testUpdateDeletedStatusEffectivelyUpdatesPreexistantNotification() {
        let expectation = self.expectation(description: "Update delete status on existing note")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let originalNote = sampleNotification()

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Note.self), 0)
        noteStore.updateLocalNotes(with: [originalNote]) { [weak self] in
            XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            let storageNote = self?.viewStorage.loadNotification(noteID: originalNote.noteId)
            XCTAssertEqual(storageNote?.deleteInProgress, false)

            noteStore.markLocalNoteAsDeleted(for: originalNote.noteId, isDeleted: true) {
                XCTAssertEqual(self?.viewStorage.countObjects(ofType: Storage.Note.self), 1)
                XCTAssertEqual(storageNote?.deleteInProgress, true)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}

// MARK: - Private Methods
//
private extension NotificationStoreTests {

    /// Returns a sample AppID
    ///
    var sampleApplicationID: String {
        return "99"
    }

    /// Returns a sample AppVersion
    ///
    var sampleApplicationVersion: String {
        return "99"
    }

    /// Returns a sample Dotcom Device ID
    ///
    var sampleDotcomDeviceID: String {
        return "1234"
    }

    /// Returns a sample Default Store ID
    ///
    var sampleDefaultStoreID: Int {
        return 1234
    }

    /// Returns a sample Apple Device
    ///
    func sampleAPNSDevice() -> APNSDevice {
        return APNSDevice(token: "1234", model: "iPhone", name: "Something", iOSVersion: "99", identifierForVendor: "1234")
    }

    /// Returns a sample Dotcom Notification
    ///
    func sampleNotification() -> Networking.Note {
        return Note(noteId: 123456,
                    hash: 11223344,
                    read: false,
                    icon: "https://gravatar.tld/some-hash",
                    noticon: "\u{f408}",
                    timestamp: "2018-10-22T18:51:33+00:00",
                    type: "comment_like",
                    subtype: nil,
                    url: "https:\\someurl.sometld",
                    title: "3 Likes",
                    subject: Data(),
                    header: Data(),
                    body: Data(),
                    meta: Data())
    }

    /// Returns a sample Dotcom Notification (same as above but slightly mutated!)
    ///
    func sampleNotificationMutated() -> Networking.Note {
        return Note(noteId: 123456,
                    hash: 11223344,
                    read: true,
                    icon: "https://gravatar.tld/some-hash",
                    noticon: "\u{f408}",
                    timestamp: "2018-10-22T18:51:33+00:00",
                    type: "comment_like",
                    subtype: nil,
                    url: "https:\\someurl.sometld",
                    title: "3 Likes",
                    subject: Data(),
                    header: Data(),
                    body: Data(),
                    meta: Data())
    }
}
