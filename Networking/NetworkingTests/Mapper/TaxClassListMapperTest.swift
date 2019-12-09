import XCTest
@testable import Networking


/// TaxClassListMapper Unit Tests
///
class TaxClassListMapperTest: XCTestCase {

    /// Verifies that all of the Tax Class Fields are parsed correctly.
    ///
    func testTaxClassFieldsAreProperlyParsed() {
        let taxClasses = mapLoadAllTaxClassResponse()
        XCTAssertEqual(taxClasses.count, 3)


        let firstTaxClass = taxClasses[0]
        XCTAssertEqual(firstTaxClass.slug, "standard")
        XCTAssertEqual(firstTaxClass.name, "Standard Rate")
    }
}


/// Private Methods.
///
private extension TaxClassListMapperTest {

    /// Returns the TaxClassListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapTaxClasses(from filename: String) -> [TaxClass] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! TaxClassListMapper().map(response: response)
    }

    /// Returns the TaxClassListMapper output upon receiving `taxes-classes`
    ///
    func mapLoadAllTaxClassResponse() -> [TaxClass] {
        return mapTaxClasses(from: "taxes-classes")
    }
}
