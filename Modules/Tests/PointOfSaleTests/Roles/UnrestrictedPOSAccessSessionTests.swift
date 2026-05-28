import Testing
@testable import PointOfSale

@MainActor
struct UnrestrictedPOSAccessSessionTests {
    @Test func test_allows_when_flag_off_then_every_capability_is_allowed() {
        // Given
        let sut = UnrestrictedPOSAccessSession()

        // When / Then
        for capability in POSCapability.allCases {
            #expect(sut.allows(capability))
        }
    }

    @Test func test_state_when_flag_off_then_unlocked_with_absent_pins() {
        // Given
        let sut = UnrestrictedPOSAccessSession()

        // When / Then - flag off means no security boundary, so `.absent` (not `.unknown`)
        // so the overlay's `pinStatus != .absent` rule resolves to "no lock screen".
        #expect(sut.isLocked == false)
        #expect(sut.pinStatus == .absent)
        #expect(sut.currentStaff == nil)
    }

    @Test func test_actions_when_flag_off_then_stay_unlocked_and_do_not_throw() async throws {
        // Given
        let sut = UnrestrictedPOSAccessSession()

        // When
        try await sut.signIn(withPIN: "1234")
        try await sut.requestManagerApproval(withPIN: "1234", for: .refundShopOrders)
        sut.lock()
        await sut.refreshPINStatus()

        // Then
        #expect(sut.isLocked == false)
        #expect(sut.currentStaff == nil)
        #expect(sut.allows(.refundShopOrders))
    }
}
