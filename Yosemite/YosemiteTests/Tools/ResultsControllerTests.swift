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
        return storage.viewContext
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
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
        XCTAssertEqual(resultsController.sections.count, 0)

        try? resultsController.performFetch()
        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 0)
    }


    /// Verifies that ResultsController does pick up pre-existant entities, right after performFetch runs.
    ///
    func testResultsControllerPicksUpEntitiesAvailablePriorToInstantiation() {
        insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 1)
    }


    /// Verifies that ResultsController does pick up entities inserted after being instantiated.
    ///
    func testResultsControllerPicksUpEntitiesInsertedAfterInstantiation() {
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        XCTAssertEqual(resultsController.sections.count, 1)
        XCTAssertEqual(resultsController.sections.first?.objects.count, 1)
    }


    /// Verifies that `sectionNameKeyPath` effectively causes the ResultsController to produce multiple sections, based on the grouping parameter.
    ///
    func testResultsControllerGroupSectionsBySectionNameKeypath() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sectionNameKeyPath: sectionNameKeyPath, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let numberOfAccounts = 100
        for _ in 0 ..< numberOfAccounts {
            insertSampleAccount(into: viewContext)
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
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sectionNameKeyPath: sectionNameKeyPath, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let mutableAccount = insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)
        let readOnlyAccount = resultsController.object(at: indexPath)

        XCTAssertEqual(Int(mutableAccount.userID), readOnlyAccount.userID)
        XCTAssertEqual(mutableAccount.displayName, readOnlyAccount.displayName)
    }


    /// Verifies that `onWillChangeContent` is called *before* anything is updated.
    ///
    func testOnWillChangeContentIsEffectivelyCalledBeforeChanges() {
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
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

        insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    /// Verifies that onDidChangeContent is effectivelyc alled *after* the results are altered.
    ///
    func testOnDidChangeContentIsEffectivelyCalledAfterChangesArePerformed() {
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
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

        insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `onDidChangeObject` is called whenever a new object is inserted.
    ///
    func testOnDidChangeObjectIsEffectivelyCalledOnceNewObjectsAreInserted() {
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        resultsController.onDidChangeObject = { (object, indexPath, type, newIndexPath) in
            let expectedIndexPath = IndexPath(row: 0, section: 0)

            XCTAssertEqual(type, .insert)
            XCTAssertEqual(newIndexPath, expectedIndexPath)
            expectation.fulfill()
        }

        insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `onDidChangeSection` is called whenever new sections are added.
    ///
    func testOnDidChangeSectionIsCalledWheneverNewSectionsAreAdded() {
        let sectionNameKeyPath = "userID"
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sectionNameKeyPath: sectionNameKeyPath, sortedBy: [sampleSortDescriptor])
        try? resultsController.performFetch()

        let expectation = self.expectation(description: "OnDidChange")
        resultsController.onDidChangeSection = { (sectionInfo, index, type) in
            XCTAssertEqual(type, .insert)
            expectation.fulfill()
        }

        insertSampleAccount(into: viewContext)
        viewContext.saveIfNeeded()

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }


    /// Verifies that `fetchedObjects` effectively  returns all of the (readOnly) objects that are expected to be available.
    ///
    func testFetchedObjectsEffectivelyReturnsAvailableEntities() {
        let sortDescriptor =  NSSortDescriptor(key: #selector(getter: Storage.Account.userID).description, ascending: true)
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sortDescriptor])
        try? resultsController.performFetch()

        let first = insertSampleAccount(into: viewContext).toReadOnly()
        let second = insertSampleAccount(into: viewContext).toReadOnly()
        let expected = [first.userID: first, second.userID: second]

        viewContext.saveIfNeeded()

        for retrieved in resultsController.fetchedObjects {
            XCTAssertEqual(retrieved.username, expected[retrieved.userID]?.username)
        }
    }
}


// MARK: - Private Helpers
//
private extension ResultsControllerTests {

    /// Inserts a new (Sample) account into the specified context.
    ///
    @discardableResult
    func insertSampleAccount(into context: NSManagedObjectContext) -> Storage.Account {
        let newAccount = context.insertNewObject(ofType: Storage.Account.self)
        newAccount.userID = Int64(arc4random())
        newAccount.displayName = "Yosemite"
        newAccount.email = "yosemite@yosemite"
        newAccount.gravatarUrl = "https://something"
        newAccount.username = "yosemite"

        return newAccount
    }
}
