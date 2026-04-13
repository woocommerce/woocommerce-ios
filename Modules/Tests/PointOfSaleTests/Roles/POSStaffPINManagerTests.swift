import Testing
@testable import PointOfSale

struct POSStaffPINManagerTests {

    // MARK: - Initial State

    @Test func test_initial_state_when_no_pins_configured_then_both_flags_are_false() {
        // Given
        let manager = makeManager()

        // Then
        #expect(manager.adminPINSet == false)
        #expect(manager.cashierPINSet == false)
        #expect(manager.hasAnyPINs == false)
    }

    @Test func test_initial_state_when_admin_pin_preconfigured_then_adminPINSet_is_true() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)

        // When
        let manager = POSStaffPINManager(pinService: pinService)

        // Then
        #expect(manager.adminPINSet == true)
        #expect(manager.cashierPINSet == false)
        #expect(manager.hasAnyPINs == true)
    }

    @Test func test_initial_state_when_both_pins_preconfigured_then_both_flags_are_true() {
        // Given
        let pinService = makePINService()
        pinService.setPIN("1234", for: .manager)
        pinService.setPIN("5678", for: .cashier)

        // When
        let manager = POSStaffPINManager(pinService: pinService)

        // Then
        #expect(manager.adminPINSet == true)
        #expect(manager.cashierPINSet == true)
        #expect(manager.hasAnyPINs == true)
    }

    // MARK: - setPIN

    @Test func test_setPIN_when_valid_admin_pin_then_updates_state_and_returns_true() {
        // Given
        let manager = makeManager()

        // When
        let result = manager.setPIN("1234", for: .manager)

        // Then
        #expect(result == true)
        #expect(manager.adminPINSet == true)
        #expect(manager.cashierPINSet == false)
        #expect(manager.hasAnyPINs == true)
    }

    @Test func test_setPIN_when_valid_cashier_pin_then_updates_state_and_returns_true() {
        // Given
        let manager = makeManager()

        // When
        let result = manager.setPIN("5678", for: .cashier)

        // Then
        #expect(result == true)
        #expect(manager.adminPINSet == false)
        #expect(manager.cashierPINSet == true)
        #expect(manager.hasAnyPINs == true)
    }

    @Test func test_setPIN_when_invalid_format_then_returns_false_and_state_unchanged() {
        // Given
        let manager = makeManager()

        // When
        let result = manager.setPIN("abc", for: .manager)

        // Then
        #expect(result == false)
        #expect(manager.adminPINSet == false)
    }

    @Test func test_setPIN_when_too_short_then_returns_false() {
        // Given
        let manager = makeManager()

        // When
        let result = manager.setPIN("12", for: .manager)

        // Then
        #expect(result == false)
        #expect(manager.adminPINSet == false)
    }

    @Test func test_setPIN_when_too_long_then_returns_false() {
        // Given
        let manager = makeManager()

        // When
        let result = manager.setPIN("1234567", for: .manager)

        // Then
        #expect(result == false)
        #expect(manager.adminPINSet == false)
    }

    @Test func test_setPIN_when_overwriting_existing_then_updates_pin() {
        // Given
        let pinService = makePINService()
        let manager = POSStaffPINManager(pinService: pinService)
        _ = manager.setPIN("1234", for: .manager)

        // When
        let result = manager.setPIN("5678", for: .manager)

        // Then
        #expect(result == true)
        #expect(manager.adminPINSet == true)
        #expect(pinService.verifyPIN("5678", for: .manager) == true)
        #expect(pinService.verifyPIN("1234", for: .manager) == false)
    }

    // MARK: - clearAllPINs

    @Test func test_clearAllPINs_when_both_set_then_removes_both() {
        // Given
        let manager = makeManager()
        _ = manager.setPIN("1234", for: .manager)
        _ = manager.setPIN("5678", for: .cashier)
        #expect(manager.hasAnyPINs == true)

        // When
        manager.clearAllPINs()

        // Then
        #expect(manager.adminPINSet == false)
        #expect(manager.cashierPINSet == false)
        #expect(manager.hasAnyPINs == false)
    }

    @Test func test_clearAllPINs_when_only_admin_set_then_clears_admin() {
        // Given
        let manager = makeManager()
        _ = manager.setPIN("1234", for: .manager)

        // When
        manager.clearAllPINs()

        // Then
        #expect(manager.adminPINSet == false)
        #expect(manager.hasAnyPINs == false)
    }

    @Test func test_clearAllPINs_when_no_pins_set_then_does_not_crash() {
        // Given
        let manager = makeManager()

        // When / Then
        manager.clearAllPINs()
        #expect(manager.hasAnyPINs == false)
    }

    // MARK: - Independence Between Roles

    @Test func test_cashier_pin_independent_of_admin() {
        // Given
        let manager = makeManager()

        // When
        _ = manager.setPIN("5678", for: .cashier)

        // Then
        #expect(manager.adminPINSet == false)
        #expect(manager.cashierPINSet == true)
    }

    @Test func test_admin_pin_independent_of_cashier() {
        // Given
        let manager = makeManager()

        // When
        _ = manager.setPIN("1234", for: .manager)

        // Then
        #expect(manager.adminPINSet == true)
        #expect(manager.cashierPINSet == false)
    }

    // MARK: - refresh

    @Test func test_refresh_when_external_change_to_service_then_picks_up_new_state() {
        // Given
        let pinService = makePINService()
        let manager = POSStaffPINManager(pinService: pinService)
        #expect(manager.adminPINSet == false)

        // When
        pinService.setPIN("1234", for: .manager)
        manager.refresh()

        // Then
        #expect(manager.adminPINSet == true)
    }

    // MARK: - Helpers

    private func makePINService() -> POSPINService {
        POSPINService(storage: InMemoryPINStorage())
    }

    private func makeManager() -> POSStaffPINManager {
        POSStaffPINManager(pinService: makePINService())
    }
}
