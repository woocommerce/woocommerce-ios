import XCTest
import WooFoundation
@testable import Yosemite
@testable import Networking
@testable import Storage

final class MarkOrderAsReadUseCaseTests: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock stores manager
    ///
    private var storesManager: MockStoresManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Sample Notes
    ///
    private lazy var sampleNotes: [Yosemite.Note] = {
        return try! mapNotes(from: "notifications-load-all")
    }()

    private var sampleNoteWithOrderID: Yosemite.Note? {
        for note in sampleNotes {
            if note.read == false, note.meta.identifier(forKey: .order) != nil {
                return note
            }
        }
        return nil
    }

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
        network = MockNetwork()

        // Need to nuke this in-between tests otherwise some will randomly fail
        NotificationStore.resetSharedDerivedStorage()
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_stores() {
        let expectation = self.expectation(description: "Mark order as read with stores")
        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        if let note = sampleNoteWithOrderID, let orderID = note.meta.identifier(forKey: .order) {
            self.storesManager.whenReceivingAction(ofType: NotificationAction.self) { action in
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
            noteStore.updateLocalNotes(with: [note]) {
                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 1)
                Task {
                    let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(stores: self.storesManager, noteID: note.noteID, orderID: orderID)
                    switch result {
                    case .success(let markedNote):
                        XCTAssertEqual(note.noteID, markedNote.noteID)
                        let storageNote = self.viewStorage.loadNotification(noteID: markedNote.noteID)
                        XCTAssertEqual(storageNote?.read, true)
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
            }
        } else {
            XCTFail()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_network() async {
        let expectation = self.expectation(description: "Mark order as read with network")

        if let note = sampleNoteWithOrderID, let orderID = note.meta.identifier(forKey: .order) {
            Task {
                self.network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
                self.network.simulateResponse(requestUrlSuffix: "notifications/read", filename: "generic_success")
                let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: self.network, noteID: note.noteID, orderID: orderID)
                switch result {
                case .success(let markedNoteID):
                    XCTAssertEqual(note.noteID, markedNoteID)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        } else {
            XCTFail()
        }
        await fulfillment(of: [expectation], timeout: Constants.expectationTimeout)
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
