import XCTest
import Yosemite
@testable import WooCommerce


/// StoresManager Unit Tests
///
class ResultsControllerUIKitTests: XCTestCase {

    /// Mockup StorageManager
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup TableView
    ///
    private var tableView: MockupTableView!

    /// Sample ResultsController
    ///
    private var resultsController: ResultsController<StorageAccount>!


    // MARK: - Overridden Methods

    override func setUp() {
        storageManager = MockupStorageManager()
        tableView = MockupTableView()

        resultsController = {
            let viewContext = storageManager.persistentContainer.viewContext
            let sectionNameKeyPath = "username"
            let descriptor = NSSortDescriptor(keyPath: \StorageAccount.userID, ascending: false)

            return ResultsController<StorageAccount>(viewStorage: viewContext, sectionNameKeyPath: sectionNameKeyPath, sortedBy: [descriptor])
        }()

        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
    }


    /// Verifies that `beginUpdates` + `endUpdates` are called in sequence.
    ///
    func testBeginAndEndUpdatesAreProperlyExecutedBeforeAndAfterPerformingUpdates() {
        let expectation = self.expectation(description: "BeginUpdates Goes First")
        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = true

        var beginUpdatesWasExecuted = false

        tableView.onBeginUpdates = {
            beginUpdatesWasExecuted = true
            expectation.fulfill()
        }

        tableView.onEndUpdates = {
            XCTAssertTrue(beginUpdatesWasExecuted)
            expectation.fulfill()
        }

        storageManager.insertSampleAccount()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that inserted entities result in `tableView.insertRows`
    ///
    func testAddingAnEntityResultsInNewRows() {
        let expectation = self.expectation(description: "Entity Insertion triggers Row Insertion")

        tableView.onInsertedRows = { rows in
            XCTAssertEqual(rows.count, 1)
            expectation.fulfill()
        }

        tableView.onReloadRows = { _ in
            XCTFail()
        }

        tableView.onDeletedRows = { _ in
            XCTFail()
        }

        storageManager.insertSampleAccount()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that deleted entities result in `tableView.deleteRows`.
    ///
    func testDeletingAnEntityResultsInDeletedRows() {
        let expectation = self.expectation(description: "Entity Deletion triggers Row Removal")

        let account = storageManager.insertSampleAccount()
        storageManager.viewStorage.saveIfNeeded()

        tableView.onDeletedRows = { rows in
            XCTAssertEqual(rows.count, 1)
            expectation.fulfill()
        }

        tableView.onInsertedRows = { _ in
            XCTFail()
        }

        tableView.onReloadRows = { _ in
            XCTFail()
        }

        storageManager.viewStorage.deleteObject(account)
        storageManager.viewStorage.saveIfNeeded()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that updated entities result in `tableView.reloadRows`.
    ///
    func testUpdatedEntityResultsInReloadedRows() {
        let expectation = self.expectation(description: "Entity Update triggers Row Reload")

        let account = storageManager.insertSampleAccount()
        storageManager.viewStorage.saveIfNeeded()

        tableView.onDeletedRows = { _ in
            XCTFail()
        }

        tableView.onInsertedRows = { _ in
            XCTFail()
        }

        tableView.onReloadRows = { rows in
            XCTAssertEqual(rows.count, 1)
            expectation.fulfill()
        }

        account.displayName = "Updated!"
        storageManager.viewStorage.saveIfNeeded()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that whenever entities are updated so that they match the "New Section Criteria", `tableView.insertSections` is
    /// effectively called.
    ///
    func testInsertSectionsIsExecutedWheneverEntitiesMatchNewSectionsCriteria() {
        let expectation = self.expectation(description: "SectionKeyPath Update Results in New Section")

        let first = storageManager.insertSampleAccount()
        let _ = storageManager.insertSampleAccount()
        storageManager.viewStorage.saveIfNeeded()

        tableView.onInsertedSections = { indexSet in
            expectation.fulfill()
        }

        tableView.onDeletedSections = { indexSet in
            XCTFail()
        }

        first.username = "Something Different Here!"
        storageManager.viewStorage.saveIfNeeded()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that deleting the last Entity gets mapped to `tableView.deleteSections`.
    ///
    func testDeletingLastEntityResultsInDeletedSection() {
        let expectation = self.expectation(description: "Zero Entities results in Deleted Sections")

        let first = storageManager.insertSampleAccount()
        storageManager.viewStorage.saveIfNeeded()

        tableView.onInsertedSections = { indexSet in
            XCTFail()
        }

        tableView.onDeletedSections = { indexSet in
            expectation.fulfill()
        }

        storageManager.viewStorage.deleteObject(first)
        storageManager.viewStorage.saveIfNeeded()
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}
