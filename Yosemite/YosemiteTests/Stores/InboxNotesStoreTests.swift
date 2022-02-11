import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking


/// InboxNotesStore Unit Tests
///
final class InboxNotesStoreTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience Property: Returns stored inbox notes count.
    ///
    private var storedInboxNotesCount: Int {
        return viewStorage.countObjects(ofType: InboxNote.self)
    }

    /// Store
    ///
    private var store: InboxNotesStore!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = InboxNotesStore(dispatcher: Dispatcher(),
                                     storageManager: storageManager,
                                     network: network)
    }

    override func tearDown() {
        store = nil
        network = nil
        storageManager = nil

        super.tearDown()
    }

    func test_loadAllInboxNotes_then_it_returns_inbox_notes_upon_successful_response() throws {
        // Given a stubbed inbox notes network response
        network.simulateResponse(requestUrlSuffix: "admin/notes", filename: "inbox-note-list")
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `loadAllInboxNotes` action
        let result: Result<[Networking.InboxNote], Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.loadAllInboxNotes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then a valid set of inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 24)
        XCTAssertTrue(result.isSuccess)
    }


    func test_loadAllInboxNotes_then_it_updates_stored_inbox_notes_upon_successful_response() {
        // Given an initial stored inbox note and a stubbed inbox notes network response
        let initialInboxNote = sampleInboxNote(id: 296)
        storageManager.insertSampleInboxNote(readOnlyInboxNote: initialInboxNote)
        network.simulateResponse(requestUrlSuffix: "admin/notes", filename: "inbox-note-list")
        XCTAssertEqual(storedInboxNotesCount, 1)

        // When dispatching a `loadAllInboxNotes` action
        let result: Result<[Networking.InboxNote], Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.loadAllInboxNotes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }


        // Then the initial inbox note should have it's values updated
        let updatedInboxNote = viewStorage.loadInboxNote(siteID: sampleSiteID, id: 296)
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotEqual(initialInboxNote.name, updatedInboxNote?.name)
        XCTAssertNotEqual(initialInboxNote.title, updatedInboxNote?.title)
        XCTAssertNotEqual(initialInboxNote.content, updatedInboxNote?.content)
    }

    func test_loadAllInboxNotes_then_it_returns_error_upon_response_error() {
        // Given a stubbed generic-error network response
        network.simulateResponse(requestUrlSuffix: "admin/notes", filename: "generic_error")
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `loadAllInboxNotes` action
        let result: Result<[Networking.InboxNote], Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.loadAllInboxNotes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 0)
        XCTAssertFalse(result.isSuccess)
    }

    func test_loadAllInboxNotes_then_it_returns_error_upon_empty_response() {
        // Given an empty network response
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `loadAllInboxNotes` action
        let result: Result<[Networking.InboxNote], Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.loadAllInboxNotes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 0)
        XCTAssertFalse(result.isSuccess)
    }

    func test_dismissInboxNote_then_it_update_inbox_note_upon_successful_response() {
        // Given a stubbed inbox note network response
        let sampleInboxNoteID: Int64 = 296
        network.simulateResponse(requestUrlSuffix: "admin/notes/\(sampleInboxNoteID)", filename: "inbox-note")

        // When dispatching a `dismissInboxNote` action
        let result: Result<Networking.InboxNote, Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.dismissInboxNote(siteID: self.sampleSiteID, noteID: sampleInboxNoteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then a valid inbox note should be stored
        XCTAssertEqual(storedInboxNotesCount, 1)
        XCTAssertTrue(result.isSuccess)
    }

    func test_dismissInboxNote_then_it_returns_error_upon_response_error() {
        // Given a stubbed generic-error network response
        let sampleInboxNoteID: Int64 = 296
        network.simulateResponse(requestUrlSuffix: "admin/notes/\(sampleInboxNoteID)", filename: "generic_error")
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `dismissInboxNote` action
        let result: Result<Networking.InboxNote, Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.dismissInboxNote(siteID: self.sampleSiteID, noteID: sampleInboxNoteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 0)
        XCTAssertFalse(result.isSuccess)
    }

    func test_dismissInboxNote_then_it_returns_error_upon_empty_response() {
        // Given an empty network response
        let sampleInboxNoteID: Int64 = 296
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `dismissInboxNote` action
        let result: Result<Networking.InboxNote, Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.dismissInboxNote(siteID: self.sampleSiteID, noteID: sampleInboxNoteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 0)
        XCTAssertFalse(result.isSuccess)
    }

    func test_markInboxNoteAsActioned_then_it_updates_stored_inbox_notes_and_inbox_action_upon_successful_response() {
        // Given a stubbed inbox note network response
        let sampleInboxNoteID: Int64 = 296
        let sampleActionID: Int64 = 13329
        let initialInboxNote = sampleInboxNote(id: 296)
        network.simulateResponse(requestUrlSuffix: "admin/notes/\(sampleInboxNoteID)/action/\(sampleActionID)", filename: "inbox-note")
        storageManager.insertSampleInboxNote(readOnlyInboxNote: initialInboxNote)
        XCTAssertEqual(storedInboxNotesCount, 1)

        // When dispatching a `markInboxNoteAsActioned` action
        let result: Result<Networking.InboxNote, Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.markInboxNoteAsActioned(siteID: self.sampleSiteID, noteID: sampleInboxNoteID, actionID: sampleActionID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then the initial inbox action should have it's values updated
        let updatedInboxNote = viewStorage.loadInboxNote(siteID: sampleSiteID, id: 296)
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotEqual(initialInboxNote.actions.first?.name, updatedInboxNote?.actions?.first?.name)
        XCTAssertNotEqual(initialInboxNote.actions.first?.label, updatedInboxNote?.actions?.first?.label)
        XCTAssertNotEqual(initialInboxNote.actions.first?.status, updatedInboxNote?.actions?.first?.status)
    }

    func test_markInboxNoteAsActioned_then_it_returns_error_upon_response_error() {
        // Given a stubbed generic-error network response
        let sampleInboxNoteID: Int64 = 296
        let sampleActionID: Int64 = 13329
        network.simulateResponse(requestUrlSuffix: "admin/notes/\(sampleInboxNoteID)/action/\(sampleActionID)", filename: "generic_error")
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `markInboxNoteAsActioned` action
        let result: Result<Networking.InboxNote, Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.markInboxNoteAsActioned(siteID: self.sampleSiteID, noteID: sampleInboxNoteID, actionID: sampleActionID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 0)
        XCTAssertFalse(result.isSuccess)
    }

    func test_markInboxNoteAsActioned_then_it_returns_error_upon_empty_response() {
        // Given an empty network response
        let sampleInboxNoteID: Int64 = 296
        let sampleActionID: Int64 = 13329
        XCTAssertEqual(storedInboxNotesCount, 0)

        // When dispatching a `markInboxNoteAsActioned` action
        let result: Result<Networking.InboxNote, Error> = waitFor { [weak self] promise in
            guard let self = self else {
                return
            }

            let action = InboxNotesAction.markInboxNoteAsActioned(siteID: self.sampleSiteID, noteID: sampleInboxNoteID, actionID: sampleActionID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then no inbox notes should be stored
        XCTAssertEqual(storedInboxNotesCount, 0)
        XCTAssertFalse(result.isSuccess)
    }
}

private extension InboxNotesStoreTests {
    func sampleInboxNote(id: Int64) -> Networking.InboxNote {
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let url = "https://woocommerce.com/products/woocommerce-bookings/"
        let content = "Get a new subscription to continue receiving updates and access to support."
        return InboxNote(siteID: sampleSiteID,
                         id: id,
                         name: "Test",
                         type: "warning",
                         status: "unactioned",
                         actions: [InboxAction(id: 13329,
                                               name: "test",
                                               label: "Test",
                                               status: "actioned",
                                               url: url)],
                         title: "This is a test",
                         content: content,
                         isRemoved: true,
                         isRead: false,
                         dateCreated: dateFormatter.date(from: "2022-01-31T14:25:32")!)
    }
}
