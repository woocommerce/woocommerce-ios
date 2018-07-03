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


    // MARK: - Overriden Methods

    override func setUp() {
        super.setUp()
        storage = MockupStorageManager()
    }


    /// Verifies thatt he ResultsController starts with zero sections, whenever there are no actual entities stored.
    ///
    func testResultsControllerStartsWithNoSectionsWhenNoAccountsAreAvailable() {
        let resultsController = ResultsController<Storage.Account>(viewContext: viewContext, sortedBy: [sampleSortDescriptor])
        XCTAssertEqual(resultsController.sections.count, 0)

        try? resultsController.performFetch()
        XCTAssertEqual(resultsController.sections.count, 0)
    }


//    let newAccount = insertSampleAccount(into: viewContext)
//    viewContext.saveIfNeeded()
}


// MARK: - Private Helpers
//
private extension ResultsControllerTests {

    /// Inserts a new (Sample) account into the specified context.
    ///
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
