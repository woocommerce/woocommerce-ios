import Testing
@testable import PointOfSale

struct POSStaffTests {
    @Test func test_hasCapability_when_staff_has_it_then_returns_true() {
        // Given
        let sut = POSStaff(userID: 1, displayName: "Jane", preset: "pos_manager", capabilities: ["woocommerce_pos_issue_refunds"])

        // When / Then
        #expect(sut.hasCapability(.issueRefunds))
    }

    @Test func test_hasCapability_when_staff_lacks_it_then_returns_false() {
        // Given
        let sut = POSStaff(userID: 2, displayName: "Sam", preset: "pos_cashier", capabilities: [])

        // When / Then
        #expect(sut.hasCapability(.issueRefunds) == false)
    }
}
