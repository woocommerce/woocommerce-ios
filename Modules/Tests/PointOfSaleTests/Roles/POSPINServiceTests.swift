import Testing
@testable import PointOfSale

struct POSPINServiceTests {

    // MARK: - Format Validation

    @Test func test_isValidFormat_when_4_digits_then_returns_true() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("1234") == true)
    }

    @Test func test_isValidFormat_when_5_digits_then_returns_true() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("12345") == true)
    }

    @Test func test_isValidFormat_when_6_digits_then_returns_true() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("123456") == true)
    }

    @Test func test_isValidFormat_when_3_digits_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("123") == false)
    }

    @Test func test_isValidFormat_when_7_digits_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("1234567") == false)
    }

    @Test func test_isValidFormat_when_contains_letters_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("12ab") == false)
    }

    @Test func test_isValidFormat_when_empty_string_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("") == false)
    }

    @Test func test_isValidFormat_when_contains_special_characters_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.isValidFormat("12#4") == false)
    }

    // MARK: - Set and Verify

    @Test func test_verifyPIN_when_correct_pin_then_returns_true() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1234", for: .manager)

        // When
        let result = sut.verifyPIN("1234", for: .manager)

        // Then
        #expect(result == true)
    }

    @Test func test_verifyPIN_when_wrong_pin_then_returns_false() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1234", for: .manager)

        // When
        let result = sut.verifyPIN("5678", for: .manager)

        // Then
        #expect(result == false)
    }

    @Test func test_verifyPIN_when_no_pin_set_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.verifyPIN("1234", for: .manager)

        // Then
        #expect(result == false)
    }

    @Test func test_verifyPIN_when_wrong_role_then_returns_false() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1234", for: .manager)

        // When
        let result = sut.verifyPIN("1234", for: .cashier)

        // Then
        #expect(result == false)
    }

    // MARK: - Delete

    @Test func test_deletePIN_when_pin_exists_then_removes_it() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1234", for: .manager)

        // When
        sut.deletePIN(for: .manager)

        // Then
        #expect(sut.hasPIN(for: .manager) == false)
        #expect(sut.verifyPIN("1234", for: .manager) == false)
    }

    @Test func test_deletePIN_when_no_pin_then_does_not_crash() {
        // Given
        let sut = makeSUT()

        // When / Then
        sut.deletePIN(for: .cashier)
        #expect(sut.hasPIN(for: .cashier) == false)
    }

    // MARK: - hasPIN

    @Test func test_hasPIN_when_pin_set_then_returns_true() {
        // Given
        let sut = makeSUT()
        sut.setPIN("9999", for: .cashier)

        // When / Then
        #expect(sut.hasPIN(for: .cashier) == true)
    }

    @Test func test_hasPIN_when_no_pin_then_returns_false() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.hasPIN(for: .cashier) == false)
    }

    // MARK: - Verify PIN (All Roles)

    @Test func test_verifyPIN_allRoles_when_manager_pin_matches_then_returns_manager() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1111", for: .manager)
        sut.setPIN("2222", for: .cashier)

        // When
        let result = sut.verifyPIN("1111")

        // Then
        #expect(result == .manager)
    }

    @Test func test_verifyPIN_allRoles_when_cashier_pin_matches_then_returns_cashier() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1111", for: .manager)
        sut.setPIN("2222", for: .cashier)

        // When
        let result = sut.verifyPIN("2222")

        // Then
        #expect(result == .cashier)
    }

    @Test func test_verifyPIN_allRoles_when_no_match_then_returns_nil() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1111", for: .manager)

        // When
        let result = sut.verifyPIN("9999")

        // Then
        #expect(result == nil)
    }

    // MARK: - PIN Update

    @Test func test_setPIN_when_overwriting_existing_then_uses_new_pin() {
        // Given
        let sut = makeSUT()
        sut.setPIN("1234", for: .manager)

        // When
        sut.setPIN("5678", for: .manager)

        // Then
        #expect(sut.verifyPIN("1234", for: .manager) == false)
        #expect(sut.verifyPIN("5678", for: .manager) == true)
    }

    // MARK: - Multiple Roles

    @Test func test_setPIN_when_different_roles_then_stores_independently() {
        // Given
        let sut = makeSUT()

        // When
        sut.setPIN("1111", for: .manager)
        sut.setPIN("2222", for: .cashier)

        // Then
        #expect(sut.verifyPIN("1111", for: .manager) == true)
        #expect(sut.verifyPIN("2222", for: .cashier) == true)
        #expect(sut.verifyPIN("1111", for: .cashier) == false)
        #expect(sut.verifyPIN("2222", for: .manager) == false)
    }

    // MARK: - Helpers

    private func makeSUT() -> POSPINService {
        POSPINService(storage: InMemoryPINStorage())
    }
}
