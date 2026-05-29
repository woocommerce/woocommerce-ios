import Testing
@testable import PointOfSale

struct POSStaffTests {
    @Test func test_hasCapability_when_staff_has_it_then_returns_true() {
        // Given
        let sut = POSStaff(displayName: "Jane", role: "pos_manager", capabilities: ["refund_shop_orders"])

        // When / Then
        #expect(sut.hasCapability(.refundShopOrders))
    }

    @Test func test_hasCapability_when_staff_lacks_it_then_returns_false() {
        // Given
        let sut = POSStaff(displayName: "Sam", role: "pos_cashier", capabilities: [])

        // When / Then
        #expect(sut.hasCapability(.refundShopOrders) == false)
    }
}
