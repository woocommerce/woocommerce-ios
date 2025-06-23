import Foundation
import XCTest
import CoreData
@testable import Storage


/// NSManagedObject+Storage Unit Tests
///
class NSManagedObjectStorageTests: XCTestCase {

    /// Verifies that the entityName method won't return an empty string.
    ///
    func test_entityName_does_not_return_empty_string() {
        XCTAssertEqual(DummyEntity.entityName, "DummyEntity")
    }
}
