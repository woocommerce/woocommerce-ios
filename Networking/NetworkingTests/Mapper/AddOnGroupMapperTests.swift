import XCTest
@testable import Networking

class AddOnGroupMapperTests: XCTestCase {

    private let dummySiteID: Int64 = 123

    func test_addOnGroups_field_are_properly_parsed() throws {
        // Given & When
        let addOnGroups = try XCTUnwrap(mapLoadGroupAddOnsResponse())

        // Then
        XCTAssertEqual(addOnGroups.count, 2)

        let firstGroup = addOnGroups[0]
        XCTAssertEqual(firstGroup.siteID, dummySiteID)
        XCTAssertEqual(firstGroup.groupID, 422)
        XCTAssertEqual(firstGroup.name, "Gifts")
        XCTAssertEqual(firstGroup.addOns.count, 2)

        let secondGroup = addOnGroups[1]
        XCTAssertEqual(secondGroup.siteID, dummySiteID)
        XCTAssertEqual(secondGroup.groupID, 427)
        XCTAssertEqual(secondGroup.name, "Music")
        XCTAssertEqual(secondGroup.addOns.count, 1)
    }
}

// MARK: JSON Loading
private extension AddOnGroupMapperTests {
    func mapLoadGroupAddOnsResponse() -> [AddOnGroup]? {
        guard let response = Loader.contentsOf("add-on-groups") else {
            return nil
        }
        return try? AddOnGroupMapper(siteID: dummySiteID).map(response: response)
    }
}
