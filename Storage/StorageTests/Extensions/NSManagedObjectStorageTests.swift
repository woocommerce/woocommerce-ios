import CoreData
import Foundation
import XCTest

@testable import Storage

/// NSManagedObject+Storage Unit Tests
///
class NSManagedObjectStorageTests: XCTestCase {

    /// Verifies that the entityName method won't return an empty string.
    ///
    func testEntityNameDoesNotReturnEmptyString() {
        XCTAssertEqual(DummyEntity.entityName, "DummyEntity")
    }
}
