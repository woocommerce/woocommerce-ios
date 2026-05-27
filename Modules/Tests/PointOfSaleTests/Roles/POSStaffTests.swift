import Testing
@testable import PointOfSale

struct POSStaffTests {
    @Test func test_hasCapability_when_staff_has_it_then_returns_true() {
        // Given
        let sut = POSStaff(userID: 1, userLogin: "jane", displayName: "Jane",
                          role: "pos_manager", capabilities: ["refund_shop_orders"])

        // When / Then
        #expect(sut.hasCapability(.refundShopOrders))
    }

    @Test func test_hasCapability_when_staff_lacks_it_then_returns_false() {
        // Given
        let sut = POSStaff(userID: 2, userLogin: "sam", displayName: "Sam",
                          role: "pos_cashier", capabilities: [])

        // When / Then
        #expect(sut.hasCapability(.refundShopOrders) == false)
    }

    @Test func test_init_when_userID_provided_then_returns_userID() {
        // Given / When
        let sut = POSStaff(userID: 42, userLogin: "mike", displayName: "Mike",
                          role: "pos_cashier", capabilities: ["view_pos"])

        // Then
        #expect(sut.userID == 42)
        #expect(sut.userLogin == "mike")
    }
}
