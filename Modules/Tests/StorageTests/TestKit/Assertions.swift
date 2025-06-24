import XCTest
import CoreData

/// Asserts that the given `NSPersistentContainer` does not contain an `NSEntityDescription` with
/// the given `entityName`.
func assertThat(container: NSPersistentContainer, hasNoEntity entityName: String, file: StaticString = #file, line: UInt = #line) {
    let description = NSEntityDescription.entity(forEntityName: entityName, in: container.viewContext)
    XCTAssertNil(description, "Expected \(entityName) to not exist in container.", file: file, line: line)
}

/// Asserts that the given `NSPersistentContainer` contains an `NSEntityDescription` with the
/// given `entityName`.
func assertThat(container: NSPersistentContainer, hasEntity entityName: String, file: StaticString = #file, line: UInt = #line) {
    let description = NSEntityDescription.entity(forEntityName: entityName, in: container.viewContext)
    XCTAssertNotNil(description, "Expected \(entityName) to exist in container.", file: file, line: line)
}
