import XCTest
import WooFoundation
import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking
@testable import NetworkingCore
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
    func test_markOrderNoteAsReadIfNeeded_with_stores_unreadNote() async throws {
        let unreadNote = try XCTUnwrap(sampleNote(read: false))
        let orderID = try XCTUnwrap(unreadNote.meta.identifier(forKey: .order))

        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        setupStoreManagerReceivingNotificationActions(for: unreadNote, noteStore: noteStore)

        await withCheckedContinuation { continuation in
            noteStore.updateLocalNotes(with: [unreadNote]) {
                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 1)
                continuation.resume()
            }
        }

        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(stores: storesManager, noteID: unreadNote.noteID, orderID: orderID)
        switch result {
        case .success(let markedNote):
            XCTAssertEqual(unreadNote.noteID, markedNote.noteID)
            let storageNote = viewStorage.loadNotification(noteID: markedNote.noteID)
            XCTAssertEqual(storageNote?.read, true)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_with_stores_alreadyReadNote() async throws {
        let readNote = try XCTUnwrap(sampleNote(read: true))
        let orderID = try XCTUnwrap(readNote.meta.identifier(forKey: .order))

        let noteStore = NotificationStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        setupStoreManagerReceivingNotificationActions(for: readNote, noteStore: noteStore)

        await withCheckedContinuation { continuation in
            noteStore.updateLocalNotes(with: [readNote]) {
                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.Note.self), 1)
                continuation.resume()
            }
        }

        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(stores: storesManager, noteID: readNote.noteID, orderID: orderID)
        switch result {
        case .success:
            XCTFail("Note was already read, it should not be marked as read again.")
        case .failure(let error):
            if case MarkOrderAsReadUseCase.Error.noNeedToMarkAsRead = error {} else {
                XCTFail("Got wrong error \(error.localizedDescription)")
            }
        }
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

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_when_note_is_missing_then_does_not_update_read_status() async {
        // Given
        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")

        // When
        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network, noteID: -1, orderID: 1)

        // Then
        guard case .failure(.unavailableNote) = result else {
            return XCTFail("Expected an unavailable note error, got \(result)")
        }
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_when_order_does_not_match_then_does_not_update_read_status() async throws {
        // Given
        let unreadNote = try XCTUnwrap(sampleNote(read: false))
        let orderID = try XCTUnwrap(unreadNote.meta.identifier(forKey: .order))
        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")

        // When
        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network,
                                                                           noteID: unreadNote.noteID,
                                                                           orderID: orderID + 1)

        // Then
        guard case .failure(.noNeedToMarkAsRead) = result else {
            return XCTFail("Expected a mismatched order to be left unread, got \(result)")
        }
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_when_loading_fails_then_returns_error_without_updating() async {
        // Given
        network.simulateError(requestUrlSuffix: "notifications", error: URLError(.notConnectedToInternet))

        // When
        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network, noteID: 1, orderID: 1)

        // Then
        guard case .failure(.failure(let error)) = result else {
            return XCTFail("Expected the loading error, got \(result)")
        }
        XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        XCTAssertEqual(network.requestsForResponseData.count, 1)
    }

    @MainActor
    func test_markOrderNoteAsReadIfNeeded_when_updating_fails_then_returns_error() async throws {
        // Given
        let unreadNote = try XCTUnwrap(sampleNote(read: false))
        let orderID = try XCTUnwrap(unreadNote.meta.identifier(forKey: .order))
        network.simulateResponse(requestUrlSuffix: "notifications", filename: "notifications-load-all")
        network.simulateError(requestUrlSuffix: "notifications/read", error: URLError(.notConnectedToInternet))

        // When
        let result = await MarkOrderAsReadUseCase.markOrderNoteAsReadIfNeeded(network: network,
                                                                           noteID: unreadNote.noteID,
                                                                           orderID: orderID)

        // Then
        guard case .failure(.failure(let error)) = result else {
            return XCTFail("Expected the read-status update error, got \(result)")
        }
        XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        XCTAssertEqual(network.requestsForResponseData.count, 2)
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
