import XCTest
import WooFoundation
@testable import Yosemite
@testable import Networking
@testable import Storage

final class MarkOrderAsReadUseCaseTests: XCTestCase {
    private var dispatcher: Dispatcher!
    private var network: MockNetwork!
    private var storageManager: MockStorageManager!
    private var storesManager: MockStoresManager!
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }
    private lazy var sampleNotes: [Yosemite.Note] = {
        return try! mapNotes(from: "notifications-load-all")
    }()

    private func sampleNote(read: Bool) -> Yosemite.Note? {
        return sampleNotes.first { note in
            return note.read == read && note.meta.identifier(forKey: .order) != nil
        }
    }

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
        network = MockNetwork()

        NotificationStore.resetSharedDerivedStorage()
    }

    override func tearDown() {
        NotificationStore.resetSharedDerivedStorage()
        super.tearDown()
    }

    private func setupStoreManagerReceivingNotificationActions(for note: Yosemite.Note, noteStore: NotificationStore) {
        storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
            switch action {
            case let .synchronizeNotifications(onCompletion):
                onCompletion(nil)
            case let .synchronizeNotification(_, onCompletion):
                onCompletion(note, nil)
            case let .updateReadStatus(noteID, read, onCompletion):
                noteStore.updateLocalNoteReadStatus(for: [noteID], read: read) {
                    onCompletion(nil)
                }
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_stores_unreadNote() throws {
        let unreadNote = try XCTUnwrap(sampleNote(read: false))
        let orderID = try XCTUnwrap(unreadNote.meta.identifier(forKey: .order))

        let expectation = expectation(description: "Mark order as read with stores")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        setupStoreManagerReceivingNotificationActions(for: unreadNote, noteStore: noteStore)

        noteStore.updateLocalNotes(with: [unreadNote]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            Task {
                let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(stores: self.storesManager, noteID: unreadNote.noteID, orderID: orderID)
                switch result {
                case .success(let markedNote):
                    XCTAssertEqual(unreadNote.noteID, markedNote.noteID)
                    let storageNote = self.viewStorage.loadNotification(noteID: markedNote.noteID)
                    XCTAssertEqual(storageNote?.read, true)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_stores_alreadyReadNote() throws {
        let readNote = try XCTUnwrap(sampleNote(read: true))
        let orderID = try XCTUnwrap(readNote.meta.identifier(forKey: .order))

        let expectation = expectation(description: "Mark order as read with stores")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        setupStoreManagerReceivingNotificationActions(for: readNote, noteStore: noteStore)

        noteStore.updateLocalNotes(with: [readNote]) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 1)
            Task {
                let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(stores: self.storesManager, noteID: readNote.noteID, orderID: orderID)
                switch result {
                case .success:
                    XCTFail("Note was already read, it should not be marked as read again.")
                case .failure(let error):
                    if case MarkOrderAsReadUseCase.Error.noNeedToMarkAsRead = error {
                        expectation.fulfill()
                    } else {
                        XCTFail("Got wrong error \(error.localizedDescription)")
                    }
                }
            }
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_network_unreadNote() async throws {
        let unreadNote = try XCTUnwrap(sampleNote(read: false))
        let orderID = try XCTUnwrap(unreadNote.meta.identifier(forKey: .order))

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_success")

        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network,
                                                                              noteID: unreadNote.noteID,
                                                                              orderID: orderID)

        switch result {
        case .success(let markedNoteID):
            XCTAssertEqual(unreadNote.noteID, markedNoteID)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_network_alreadyReadNote() async throws {
        let readNote = try XCTUnwrap(sampleNote(read: true))
        let orderID = try XCTUnwrap(readNote.meta.identifier(forKey: .order))

        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")

        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network,
                                                                              noteID: readNote.noteID,
                                                                              orderID: orderID)

        switch result {
        case .success:
            XCTFail("Note was already read, it should not be marked as read again.")
        case .failure(let error):
            if case MarkOrderAsReadUseCase.Error.noNeedToMarkAsRead = error {} else {
                XCTFail("Got wrong error \(error.localizedDescription)")
            }
        }
    }
}

/// Private Methods.
///
private extension MarkOrderAsReadUseCaseTests {

    /// Returns the NoteListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapNotes(from filename: String) throws -> [Yosemite.Note] {
        let response = Loader.contentsOf(filename)!
        return try NoteListMapper().map(response: response)
    }
}
