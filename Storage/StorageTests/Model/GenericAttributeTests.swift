import XCTest

@testable import Storage

/// Test cases for the `GenericAttribute` NSManagedObject class.
final class GenericAttributeTests: XCTestCase {

    private var coreDataManager: CoreDataManager!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        coreDataManager = nil
        super.tearDown()
    }

    func test_entityName_is_GenericAttribute() {
        let entityName = GenericAttribute.entityName

        XCTAssertEqual(entityName, "GenericAttribute")
    }

    func test_entity_name_from_NSManagedObject_instance_is_GenericAttribute() {
        let attribute = coreDataManager.viewStorage.insertNewObject(ofType: GenericAttribute.self)

        let entityName = attribute.entity.name

        XCTAssertEqual(entityName, "GenericAttribute")
    }
}
