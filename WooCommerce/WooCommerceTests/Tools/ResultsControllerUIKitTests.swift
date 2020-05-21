import XCTest
import Yosemite
import protocol Storage.StorageType

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

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }


    // MARK: - Overridden Methods

    override func setUp() {
        storageManager = MockupStorageManager()
        tableView = MockupTableView()

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

        resultsController.startForwardingEvents(to: tableView)
        try? resultsController.performFetch()
    }

    override func tearDown() {
        resultsController = nil
        tableView = nil
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

    func testSomething() {
//        for _ in 0..<100 {
            runScenario()
//        }
    }

    private func runScenario() {
        tableView.dataSource = self

        var expectation = self.expectation(description: "SectionKeyPath Update Results in New Section")
        tableView.onEndUpdates = {
            expectation.fulfill()
        }

        let alphaSection = [
            insertAccount(section: "Alpha", userID: 3),
            insertAccount(section: "Alpha", userID: 2),
            insertAccount(section: "Alpha", userID: 1)
        ]

        let betaSection = [
            insertAccount(section: "Beta", userID: 3),
            insertAccount(section: "Beta", userID: 2),
            insertAccount(section: "Beta", userID: 1)
        ]

        let charlieSection = [
            insertAccount(section: "Charlie", userID: 4),
            insertAccount(section: "Charlie", userID: 2),
            insertAccount(section: "Charlie", userID: 1)
        ]

        viewStorage.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)

//        XCTAssertEqual(tableView.numberOfSections, 3)

        ///

        expectation = self.expectation(description: "SectionKeyPath Update Results in New Section")
        tableView.onEndUpdates = {
            expectation.fulfill()
        }

        // --

        insertAccount(section: "Alpha", userID: 2)

        betaSection[1].displayName = "woot"
        betaSection.forEach(viewStorage.deleteObject)

        insertAccount(section: "Charlie", userID: 3)

        alphaSection.forEach {
            $0.displayName = "fake"
        }
        alphaSection[1].userID = 4
//
//        charlieSection[1].userID = 99

        // --

        viewStorage.saveIfNeeded()

        wait(for: [expectation], timeout: Constants.expectationTimeout)

//        XCTAssertEqual(tableView.numberOfSections, 2)
//        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 4)
//        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 3)
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

    @discardableResult
    func insertAccount(section username: String, userID: Int64) -> StorageAccount {
        let account = storageManager.insertSampleAccount()
        account.username = username
        account.userID = userID
        return account
    }
}
