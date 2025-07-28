import Foundation
import Testing
@testable import PointOfSale

struct PointOfSaleTests {

    @Test func module_version_is_correct() async throws {
        // Given
        let expectedVersion = "1.0.0"

        // When
        let actualVersion = PointOfSale.version

        // Then
        #expect(actualVersion == expectedVersion)
    }

    @Test func initialize_does_not_throw() async throws {
        // When, Then
        // Should not throw any errors
        PointOfSale.initialize()
    }
}
