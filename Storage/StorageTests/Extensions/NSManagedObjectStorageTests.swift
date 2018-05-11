import Foundation
import XCTest
import CoreData
@testable import Storage


/// NSManagedObject+Storage Unit Tests
///
class NSManagedObjectStorageTests: XCTestCase {

    /// Verifies that newFetchRequest effectively returns a new Request associated to the Stack's specialized type.
    ///
    func testNewFetchRequestReturnsNewRequestWithGenericEntityName() {
        XCTAssertEqual(DummyEntity.safeFetchRequest().entityName, DummyEntity.entityName())
    }

    /// Verifies that the entityName method won't return an empty string.
    ///
    func testEntityNameDoesNotReturnEmptyString() {
        XCTAssertEqual(DummyEntity.entityName(), "DummyEntity")
    }
}
