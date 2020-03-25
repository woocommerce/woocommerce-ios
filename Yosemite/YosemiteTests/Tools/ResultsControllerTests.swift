import XCTest
import Storage
import CoreData
@testable import Yosemite



// MARK: - ResultsController Unit Tests
//
class ResultsControllerTests: XCTestCase {

    /// InMemory Storage!
    ///
    private var storage: MockupStorageManager!

    /// Returns the NSMOC associated to the Main Thread
    ///
    private var viewContext: NSManagedObjectContext {
        return storage.persistentContainer.viewContext
    }

    /// Returns a sample NSSortDescriptor
    ///
    private var sampleSortDescriptor: NSSortDescriptor {
        return NSSortDescriptor(key: #selector(getter: Storage.Account.displayName).description, ascending: true)
    }


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        storage = MockupStorageManager()
    }


    /// Verifies that the Results Controller has an Empty Section right after the Fetch OP is performed.
    ///
    func testResultsControllerStartsEmptySectionAfterPerformingFetch() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sampleSortDescriptor])
        XCTAssertEqual(resultsController.sections.count, 0)

        try? resultsController.performFetch()
        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 0)
    }


    /// Verifies that ResultsController does pick up pre-existant entities, right after performFetch runs.
    ///
    func testResultsControllerPicksUpEntitiesAvailablePriorToInstantiation() {
        storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 1)
    }


    /// Verifies that ResultsController does pick up entities inserted after being instantiated.
    ///
    func testResultsControllerPicksUpEntitiesInsertedAfterInstantiation() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 1)
    }


    /// Verifies that `sectionNameKeyPath` effectively causes the ResultsController to produce multiple sections, based on the grouping parameter.
    ///
    func testResultsControllerGroupSectionsBySectionNameKeypath() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext,
                                                                   sectionNameKeyPath: sectionNameKeyPath,
                                                                   sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let numberOfAccounts = 100
        for _ in 0 ..< numberOfAccounts {
            storage.insertSampleAccount()
        }

        viewContext.saveIfNeeded()

        XCTAssertEqual(resultsController.sections.count, numberOfAccounts)

        for section in resultsController.sections {
            XCTAssertEqual(section.numberOfObjects, 1)
        }
    }


    /// Verifies that `object(at indexPath:)` effectively returns the expected (ReadOnly) Entity.
    ///
    func testObjectAtIndexPathReturnsExpectedEntity() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext,
                                                                   sectionNameKeyPath: sectionNameKeyPath,
                                                                   sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let mutableAccount = storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)
        let readOnlyAccount = resultsController.object(at: indexPath)

        XCTAssertEqual(mutableAccount.userID, readOnlyAccount.userID)
        XCTAssertEqual(mutableAccount.displayName, readOnlyAccount.displayName)
    }


    /// Verifies that `onWillChangeContent` is called *before* anything is updated.
    ///
    func testOnWillChangeContentIsEffectivelyCalledBeforeChanges() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sampleSortDescriptor])
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

        storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that onDidChangeContent is effectivelyc alled *after* the results are altered.
    ///
    func testOnDidChangeContentIsEffectivelyCalledAfterChangesArePerformed() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sampleSortDescriptor])
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

        storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `onDidChangeObject` is called whenever a new object is inserted.
    ///
    func testOnDidChangeObjectIsEffectivelyCalledOnceNewObjectsAreInserted() {
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        resultsController.onDidChangeObject = { (object, indexPath, type, newIndexPath) in
            let expectedIndexPath = IndexPath(row: 0, section: 0)

            XCTAssertEqual(type, .insert)
            XCTAssertEqual(newIndexPath, expectedIndexPath)
            expectation.fulfill()
        }

        storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `onDidChangeSection` is called whenever new sections are added.
    ///
    func testOnDidChangeSectionIsCalledWheneverNewSectionsAreAdded() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext,
                                                                   sectionNameKeyPath: sectionNameKeyPath,
                                                                   sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        resultsController.onDidChangeSection = { (sectionInfo, index, type) in
            XCTAssertEqual(type, .insert)
            expectation.fulfill()
        }

        storage.insertSampleAccount()
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `fetchedObjects` effectively  returns all of the (readOnly) objects that are expected to be available.
    ///
    func testFetchedObjectsEffectivelyReturnsAvailableEntities() {
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        let first = storage.insertSampleAccount().toReadOnly()
        let second = storage.insertSampleAccount().toReadOnly()
        let expected = [first.userID: first, second.userID: second]

        viewContext.saveIfNeeded()

        for retrieved in resultsController.fetchedObjects {
            XCTAssertEqual(retrieved.username, expected[retrieved.userID]?.username)
        }
    }


    /// Verifies that `fetchedObjects` effectively  returns all of the (readOnly) objects that are expected to be available.
    ///
    func testResettingStorageIsMappedIntoOnResetClosure() {
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        storage.insertSampleAccount()
        storage.insertSampleAccount()

        viewContext.saveIfNeeded()
        XCTAssertEqual(resultsController.fetchedObjects.count, 2)

        let expectation = self.expectation(description: "OnDidReset")
        resultsController.onDidResetContent = {
            expectation.fulfill()
        }

        storage.reset()
        XCTAssertTrue(resultsController.isEmpty)

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `numberOfObjects` returns zero, when the collection is empty.
    ///
    func testEmptyStorageReturnsZeroNumberOfObjects() {
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        XCTAssertEqual(resultsController.numberOfObjects, 0)
    }


    /// Verifies that `objectIndex(from indexPath:)` returns a plain Integer that can be used to retrive the target Object
    /// from the `fetchedObjects` collection.
    ///
    func testObjectIndexFromIndexPathReturnsAPlainIndexThatLetsYouMapTheProperObject() {
        let sectionNameKeyPath = "displayName"
        let sortDescriptor = NSSortDescriptor(key: #selector(getter: Storage.Account.username).description, ascending: true)

        let resultsController = ResultsController<Storage.Account>(viewStorage: viewContext, sectionNameKeyPath: sectionNameKeyPath, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        let numberOfSections = 100
        let numberOfObjectsPerSection = 2

        for section in 0..<numberOfSections {
            for row in 0..<numberOfObjectsPerSection {
                let account = storage.insertSampleAccount()

                // We're sorting by Username (and grouping by  displayName
                let plainIndex = section * numberOfObjectsPerSection + row
                account.username = "\(plainIndex)"
                account.displayName = "\(section)"
            }
        }

        viewContext.saveIfNeeded()

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
