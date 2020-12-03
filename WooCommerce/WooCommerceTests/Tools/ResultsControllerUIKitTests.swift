import XCTest
import TestKit
import Yosemite

import protocol Storage.StorageType

@testable import WooCommerce


/// StoresManager Unit Tests
///
final class ResultsControllerUIKitTests: XCTestCase {

    /// Mock StorageManager
    ///
    private var storageManager: MockStorageManager!

    /// Mock TableView
    ///
    private var tableView: MockTableView!

    /// Sample ResultsController
    ///
    private var resultsController: ResultsController<StorageAccount>!

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()

        resultsController = {
            let viewStorage = storageManager.viewStorage
            let sectionNameKeyPath = "username"
            let descriptor = NSSortDescriptor(keyPath: \StorageAccount.userID, ascending: false)

            return ResultsController<StorageAccount>(
                    viewStorage: viewStorage,
                    sectionNameKeyPath: sectionNameKeyPath,
                    sortedBy: [descriptor]
            )
        }()

        tableView = MockTableView()
        tableView.dataSource = self

        resultsController.startForwardingEvents(to: tableView)
        try! resultsController.performFetch()
    }

    override func tearDown() {
        tableView.dataSource = nil
        tableView = nil
        resultsController = nil
        storageManager = nil
        super.tearDown()
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

    /// Tests that `ResultsController` can handle a simultataneous section deletion, row deletion,
    /// and row insertion.
    ///
    /// This scenario is based on the Ordering of Operations and Index Paths section in
    /// [this Apple Doc](https://tinyurl.com/yc3379jb)
    ///
    func testItCanHandleSimultaneousSectionAndRowDeletionAndInsertion() {
        // Given
        // Add the table to a UIWindow so that it will crash in case an invalid number of rows
        // is detected.
        let window = makeWindow(containing: tableView)
        window.isHidden = false

        // Set up initial rows and sections.
        let firstSection = [
            insertAccount(section: "Alpha", userID: 9_900),
            insertAccount(section: "Alpha", userID: 9_800),
            insertAccount(section: "Alpha", userID: 9_700)
        ]

        let secondSection = [
            insertAccount(section: "Beta", userID: 8_900),
            insertAccount(section: "Beta", userID: 8_800),
            insertAccount(section: "Beta", userID: 8_700)
        ]

        let _ = [
            insertAccount(section: "Charlie", userID: 7_900),
            insertAccount(section: "Charlie", userID: 7_800),
            insertAccount(section: "Charlie", userID: 7_700)
        ]

        saveAndWaitForTableViewOnEndUpdates()

        XCTAssertEqual(tableView.numberOfSections, 3)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 3)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 3)
        XCTAssertEqual(tableView.numberOfRows(inSection: 2), 3)

        // When
        // Delete row at index 1 of section at index 0.
        viewStorage.deleteObject(firstSection[1])
        // Delete section at index 1
        secondSection.forEach(viewStorage.deleteObject)
        // Insert row at index 1 of section at index 1.
        insertAccount(section: "Charlie", userID: 7_801)

        saveAndWaitForTableViewOnEndUpdates()

        // Then
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 4)
    }

    /// Test that `ResultsController` will emit a `move` `ChangeType` if a row is moved to
    /// a new section because of an update to a property used as the `sectionNameKeyPath`.
    ///
    /// This proves that the bug discussed in [here](https://forums.developer.apple.com/thread/61282)
    /// was already fixed by Apple. The bug was that a `move` was being emitted as an `update`.
    ///
    func testWhenARowIsMovedToANewSectionThenAMoveChangeTypeEventIsEmitted() {
        // Given
        // Add the table to a UIWindow so that it will crash in case an invalid number of rows
        // is detected.
        let window = makeWindow(containing: tableView)
        window.isHidden = false

        // Set up initial rows and sections.
        let _ = [
            insertAccount(section: "Alpha", userID: 9_900),
            insertAccount(section: "Alpha", userID: 9_800),
            insertAccount(section: "Alpha", userID: 9_700)
        ]

        let secondSection = [
            insertAccount(section: "Beta", userID: 8_900),
            insertAccount(section: "Beta", userID: 8_800),
            insertAccount(section: "Beta", userID: 8_700)
        ]

        saveAndWaitForTableViewOnEndUpdates()

        // When
        var insertedRows = [IndexPath]()
        var deletedRows = [IndexPath]()
        var reloadedRows = [IndexPath]()
        tableView.onInsertedRows = {
            insertedRows.append(contentsOf: $0)
        }
        tableView.onDeletedRows = {
            deletedRows.append(contentsOf: $0)
        }
        tableView.onReloadRows = {
            reloadedRows.append(contentsOf: $0)
        }

        // Move a row to a new section
        secondSection[1].username = "Foxtrot"

        saveAndWaitForTableViewOnEndUpdates()

        // Then
        // A `.move` change type is handled as both a delete and then an insert
        XCTAssertEqual(deletedRows, [IndexPath(row: 1, section: 1)])
        XCTAssertEqual(insertedRows, [IndexPath(row: 0, section: 2)])
        assertEmpty(reloadedRows)

        XCTAssertEqual(tableView.numberOfSections, 3)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 3)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 2), 1)
    }

    /// Test that when a row is updated and, at the same time, was moved because of an update
    /// from a different row, then we consider that as a `.move` instead of a `.update`.
    ///
    /// FRC emits a `.update` for this with `indexPath` and `newIndexPath` having different values.
    /// When this happens, we change it to `.move`. See the `fixedType` variable in
    /// `ResultsController.startForwardingObjectEvents` for more info.
    ///
    /// Something to note, if we just use `reloadRows`, `UITableView` actually considers that
    /// as both a delete and insert operation. Without the `fixedType`, iOS will crash with
    /// an error like this:
    ///
    /// ```
    /// attempt to delete row 0 from section 2, but there are only 2 sections before the
    /// update with userInfo...
    /// ```
    ///
    func testWhenARowIsUpdatedAndMovedBecauseOfANewSectionThenAMoveChangeTypeEventIsEmitted() {
        // Given
        // Add the table to a UIWindow so that it will crash in case an invalid number of rows
        // is detected.
        let window = makeWindow(containing: tableView)
        window.isHidden = false

        // Set up initial rows and sections.
        let _ = [
            insertAccount(section: "Alpha", userID: 9_900),
        ]

        let charlieSection = [
            insertAccount(section: "Charlie", userID: 7_900),
        ]

        saveAndWaitForTableViewOnEndUpdates()

        // When
        var insertedRows = [IndexPath]()
        var deletedRows = [IndexPath]()
        var reloadedRows = [IndexPath]()
        tableView.onInsertedRows = {
            insertedRows.append(contentsOf: $0)
        }
        tableView.onDeletedRows = {
            deletedRows.append(contentsOf: $0)
        }
        tableView.onReloadRows = {
            reloadedRows.append(contentsOf: $0)
        }

        // Insert a section above `charlieSection`.
        insertAccount(section: "Beta", userID: 8_900)
        // Update the charlieSection row. This will emit an `.update` change type which we
        // will fix by changing to a `.move`. See ResultsController.startForwardObjectEvents.
        charlieSection[0].displayName = "Updated DisplayName"

        saveAndWaitForTableViewOnEndUpdates()

        // Then
        // A `.move` change type is handled as both a delete and then an insert
        XCTAssertEqual(deletedRows, [IndexPath(row: 0, section: 1)])
        XCTAssertEqual(insertedRows, [IndexPath(row: 0, section: 1), IndexPath(row: 0, section: 2)])
        assertEmpty(reloadedRows)

        XCTAssertEqual(tableView.numberOfSections, 3)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 2), 1)
    }
}

// MARK: - UITableViewDataSource

extension ResultsControllerUIKitTests: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        resultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        resultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
}

// MARK: - Utils

private extension ResultsControllerUIKitTests {
    /// Create an account belonging to a section.
    ///
    /// The `section` is really just the `username`. This is just how we configured it in `setUp()`.
    ///
    @discardableResult
    func insertAccount(section username: String, userID: Int64) -> StorageAccount {
        let account = storageManager.insertSampleAccount()
        account.username = username
        account.userID = userID
        return account
    }

    /// Save the `viewStorage` and wait for `self.tableView`'s `onEndUpdates` (cell animations)
    /// to be called.
    ///
    func saveAndWaitForTableViewOnEndUpdates() {
        let expectOnEndUpdates = self.expectation(description: "wait for onEndUpdates")
        tableView.onEndUpdates = {
            expectOnEndUpdates.fulfill()
        }

        viewStorage.saveIfNeeded()

        wait(for: [expectOnEndUpdates], timeout: Constants.expectationTimeout)
    }

    /// Create a UIWindow containing the given `tableView`.
    ///
    func makeWindow(containing tableView: UITableView) -> UIWindow {
        let rootViewController = UIViewController()
        rootViewController.view.addSubview(tableView)

        let window = UIWindow(frame: .zero)
        window.rootViewController = rootViewController

        return window
    }
}
