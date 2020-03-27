import XCTest
import Storage
import CoreData
@testable import Yosemite



// MARK: - ResultsController Unit Tests
//
class ResultsControllerTests: XCTestCase {

    /// InMemory Storage!
    ///
    private var storageManager: MockupStorageManager!

    /// Returns the `StorageType` associated with the Main Thread
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Returns a sample NSSortDescriptor
    ///
    private var sampleSortDescriptor: NSSortDescriptor {
        return NSSortDescriptor(key: #selector(getter: Storage.Account.displayName).description, ascending: true)
    }


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    /// Verifies that the Results Controller has an Empty Section right after the Fetch OP is performed.
    ///
    func testResultsControllerStartsEmptySectionAfterPerformingFetch() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sampleSortDescriptor])
        XCTAssertEqual(resultsController.sections.count, 0)

        try? resultsController.performFetch()
        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 0)
    }


    /// Verifies that ResultsController does pick up pre-existant entities, right after performFetch runs.
    ///
    func testResultsControllerPicksUpEntitiesAvailablePriorToInstantiation() {
        storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 1)
    }


    /// Verifies that ResultsController does pick up entities inserted after being instantiated.
    ///
    func testResultsControllerPicksUpEntitiesInsertedAfterInstantiation() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 1)
    }


    /// Verifies that `sectionNameKeyPath` effectively causes the ResultsController to produce multiple sections, based on the grouping parameter.
    ///
    func testResultsControllerGroupSectionsBySectionNameKeypath() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage,
                                                                   sectionNameKeyPath: sectionNameKeyPath,
                                                                   sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let numberOfAccounts = 100
        for _ in 0 ..< numberOfAccounts {
            storageManager.insertSampleAccount()
        }

        viewStorage.saveIfNeeded()

        XCTAssertEqual(resultsController.sections.count, numberOfAccounts)

        for section in resultsController.sections {
            XCTAssertEqual(section.numberOfObjects, 1)
        }
    }


    /// Verifies that `object(at indexPath:)` effectively returns the expected (ReadOnly) Entity.
    ///
    func testObjectAtIndexPathReturnsExpectedEntity() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage,
                                                                   sectionNameKeyPath: sectionNameKeyPath,
                                                                   sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let mutableAccount = storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)
        let readOnlyAccount = resultsController.object(at: indexPath)

        XCTAssertEqual(mutableAccount.userID, readOnlyAccount.userID)
        XCTAssertEqual(mutableAccount.displayName, readOnlyAccount.displayName)
    }


    /// Verifies that `onWillChangeContent` is called *before* anything is updated.
    ///
    func testOnWillChangeContentIsEffectivelyCalledBeforeChanges() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnWillChange")
        var didChangeObjectWasCalled = false

        resultsController.onWillChangeContent = {
            XCTAssertFalse(didChangeObjectWasCalled)
            expectation.fulfill()
        }
        resultsController.onDidChangeObject = { (_, _, _, _) in
            didChangeObjectWasCalled = true
        }

        storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that onDidChangeContent is effectivelyc alled *after* the results are altered.
    ///
    func testOnDidChangeContentIsEffectivelyCalledAfterChangesArePerformed() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        var didChangeObjectWasCalled = false

        resultsController.onDidChangeObject = { (_, _, _, _) in
            didChangeObjectWasCalled = true
        }
        resultsController.onDidChangeContent = {
            XCTAssertTrue(didChangeObjectWasCalled)
            expectation.fulfill()
        }

        storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `onDidChangeObject` is called whenever a new object is inserted.
    ///
    func testOnDidChangeObjectIsEffectivelyCalledOnceNewObjectsAreInserted() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        resultsController.onDidChangeObject = { (object, indexPath, type, newIndexPath) in
            let expectedIndexPath = IndexPath(row: 0, section: 0)

            XCTAssertEqual(type, .insert)
            XCTAssertEqual(newIndexPath, expectedIndexPath)
            expectation.fulfill()
        }

        storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `onDidChangeSection` is called whenever new sections are added.
    ///
    func testOnDidChangeSectionIsCalledWheneverNewSectionsAreAdded() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage,
                                                                   sectionNameKeyPath: sectionNameKeyPath,
                                                                   sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        resultsController.onDidChangeSection = { (sectionInfo, index, type) in
            XCTAssertEqual(type, .insert)
            expectation.fulfill()
        }

        storageManager.insertSampleAccount()
        viewStorage.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `fetchedObjects` effectively  returns all of the (readOnly) objects that are expected to be available.
    ///
    func testFetchedObjectsEffectivelyReturnsAvailableEntities() {
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        let first = storageManager.insertSampleAccount().toReadOnly()
        let second = storageManager.insertSampleAccount().toReadOnly()
        let expected = [first.userID: first, second.userID: second]

        viewStorage.saveIfNeeded()

        for retrieved in resultsController.fetchedObjects {
            XCTAssertEqual(retrieved.username, expected[retrieved.userID]?.username)
        }
    }


    /// Verifies that `fetchedObjects` effectively  returns all of the (readOnly) objects that are expected to be available.
    ///
    func testResettingStorageIsMappedIntoOnResetClosure() {
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        storageManager.insertSampleAccount()
        storageManager.insertSampleAccount()

        viewStorage.saveIfNeeded()
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)

        let expectation = self.expectation(description: "OnDidReset")
        resultsController.onDidResetContent = {
            expectation.fulfill()
        }

        storageManager.reset()
        XCTAssertTrue(resultsController.isEmpty)

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `numberOfObjects` returns zero, when the collection is empty.
    ///
    func testEmptyStorageReturnsZeroNumberOfObjects() {
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        XCTAssertEqual(resultsController.numberOfObjects, 0)
    }


    /// Verifies that `objectIndex(from indexPath:)` returns a plain Integer that can be used to retrive the target Object
    /// from the `fetchedObjects` collection.
    ///
    func testObjectIndexFromIndexPathReturnsAPlainIndexThatLetsYouMapTheProperObject() {
        let sectionNameKeyPath = "displayName"
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.username).description, ascending: true)

        let resultsController = ResultsController<Storage.Account>(viewStorage: viewStorage, sectionNameKeyPath: sectionNameKeyPath, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        let numberOfSections = 100
        let numberOfObjectsPerSection = 2

        for section in 0..<numberOfSections {
            for row in 0..<numberOfObjectsPerSection {
                let account = storageManager.insertSampleAccount()

                // We're sorting by Username (and grouping by  displayName
                let plainIndex = section * numberOfObjectsPerSection + row
                account.username = "\(plainIndex)"
                account.displayName = "\(section)"
            }
        }

        viewStorage.saveIfNeeded()

        for (sectionNumber, sectionObject) in resultsController.sections.enumerated() {
            for (row, object) in sectionObject.objects.enumerated() {
                let indexPath = IndexPath(row: row, section: sectionNumber)
                let objectIndex = resultsController.objectIndex(from: indexPath)
                let expected = resultsController.object(at: indexPath)
                let retrieved = resultsController.fetchedObjects[objectIndex]

                XCTAssertEqual(retrieved.userID, expected.userID)
                XCTAssertEqual(object.userID, expected.userID)
            }
        }
    }
}
