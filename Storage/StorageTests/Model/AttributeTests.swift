import XCTest

@testable import Storage

/// Test cases for the `Attribute` NSManagedObject class.
final class AttributeTests: XCTestCase {

    private var coreDataManager: CoreDataManager!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        coreDataManager = nil
        super.tearDown()
    }

    func test_entityName_is_Attribute() {
        let entityName = Attribute.entityName

        XCTAssertEqual(entityName, "GenericAttribute")
    }

    func test_entity_name_from_NSManagedObject_instance_is_Attribute() {
        let attribute = coreDataManager.viewStorage.insertNewObject(ofType: Attribute.self)

        let entityName = attribute.entity.name

        XCTAssertEqual(entityName, "GenericAttribute")
    }
}
