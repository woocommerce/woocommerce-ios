import XCTest
@testable import Storage
import CoreData



/// NSObject+Storage Unit Tests
///
class NSObjectStorageTests: XCTestCase {

    /// Verifies taht `classNameWithoutNamespaces` effectively removes the Module Name's Prefix.
    ///
    func testClassnameWithoutNamespacesDoesNotReturnModuleNamePrefix() {
        let dummyClass = DummyEntity.self
        XCTAssertEqual(dummyClass.classNameWithoutNamespaces(), "DummyEntity")
    }
}
