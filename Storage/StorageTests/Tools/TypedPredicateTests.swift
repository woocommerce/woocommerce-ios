import XCTest
@testable import Storage

final class TypedPredicateTests: XCTestCase {

    func test_EQUAL_operator_produces_correct_predicate() {
        let predicate = \Dummy.dummyID == 20
        XCTAssertEqual(predicate.predicateFormat, "dummyID == 20")
    }

    func test_NOT_EQUAL_operator_produces_correct_predicate() {
        let predicate = \Dummy.dummyID != 20
        XCTAssertEqual(predicate.predicateFormat, "dummyID != 20")
    }

    func test_IN_operator_produces_correct_predicate() {
        let predicate = \Dummy.dummyID === [20, 21, 22]
        XCTAssertEqual(predicate.predicateFormat, "dummyID IN {20, 21, 22}")
    }

    func test_AND_operator_produces_correct_predicate() {
        let predicate = \Dummy.dummyID == 20 && \Dummy.name =~ "name"
        XCTAssertEqual(predicate.predicateFormat, "dummyID == 20 AND name ==[c] \"name\"")
    }

    func test_OR_operator_produces_correct_predicate() {
        let predicate = \Dummy.dummyID == 20 || \Dummy.name =~ "name"
        XCTAssertEqual(predicate.predicateFormat, "dummyID == 20 OR name ==[c] \"name\"")
    }

    func test_multiple_operators_produces_correct_predicate() {
        let predicate = \Dummy.dummyID == 20 || \Dummy.name =~ "name" && \Dummy.slug === ["slug", "name"]
        XCTAssertEqual(predicate.predicateFormat, "dummyID == 20 OR (name ==[c] \"name\" AND slug IN {\"slug\", \"name\"})")
    }
}

/// Dummy class that is key path accessible
///
private class Dummy {
    @objc let dummyID: Int = 20
    @objc let name: String = "name"
    @objc let slug: String = "slug"
}
