import XCTest
import CoreData

func assertThat(container: NSPersistentContainer, hasNoEntity entityName: String, file: StaticString = #file, line: UInt = #line) {
    let description = NSEntityDescription.entity(forEntityName: entityName, in: container.viewContext)
    XCTAssertNil(description, "Expected \(entityName) to not exist in container.", file: file, line: line)
}

func assertThat(container: NSPersistentContainer, hasEntity entityName: String, file: StaticString = #file, line: UInt = #line) {
    let description = NSEntityDescription.entity(forEntityName: entityName, in: container.viewContext)
    XCTAssertNotNil(description, "Expected \(entityName) to exist in container.", file: file, line: line)
}
