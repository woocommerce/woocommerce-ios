import Testing
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSPINAuthenticatorTests {
    @Test func test_authenticate_when_pin_matches_admin_then_returns_admin_staff() async throws {
        // Given
        let sut = try makeSUT(adminPIN: "1234", cashierPIN: "5678")

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then
        #expect(staff == POSLocalRole.admin.staff)
    }

    @Test func test_authenticate_when_pin_matches_cashier_then_returns_cashier_staff() async throws {
        // Given
        let sut = try makeSUT(adminPIN: "1234", cashierPIN: "5678")

        // When
        let staff = try await sut.authenticate(withPIN: "5678")

        // Then
        #expect(staff == POSLocalRole.cashier.staff)
        #expect(staff.hasCapability(.issueRefunds) == false)
    }

    @Test func test_authenticate_when_pin_is_wrong_then_throws_invalidPIN() async throws {
        // Given
        let sut = try makeSUT(adminPIN: "1234")

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: "0000")
        }
    }

    @Test func test_authenticate_when_no_pins_are_set_then_throws_invalidPIN() async {
        // Given
        let sut = DefaultPOSPINAuthenticator(credentialProvider: MockPOSPINCredentialProvider())

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: "1234")
        }
    }

    @Test func test_authenticate_when_credentials_are_unreadable_then_throws_unknown() async {
        // Given
        let provider = MockPOSPINCredentialProvider(credentialsResult: .failure(.storageFailure))
        let sut = DefaultPOSPINAuthenticator(credentialProvider: provider)

        // When / Then
        await #expect(throws: POSAuthError.unknown) {
            _ = try await sut.authenticate(withPIN: "1234")
        }
    }

    @Test func test_verify_when_admin_pin_approves_refund_then_succeeds() async throws {
        // Given
        let sut = try makeSUT(adminPIN: "1234", cashierPIN: "5678")

        // When / Then
        try await sut.verify(managerPIN: "1234", authorizes: .issueRefunds)
    }

    @Test func test_verify_when_cashier_pin_approves_refund_then_throws_invalidPIN() async throws {
        // Given
        let sut = try makeSUT(adminPIN: "1234", cashierPIN: "5678")

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            try await sut.verify(managerPIN: "5678", authorizes: .issueRefunds)
        }
    }

    @Test func test_verify_when_pin_is_wrong_then_throws_invalidPIN() async throws {
        // Given
        let sut = try makeSUT(adminPIN: "1234")

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            try await sut.verify(managerPIN: "0000", authorizes: .exitPOS)
        }
    }
}

private extension DefaultPOSPINAuthenticatorTests {
    func makeSUT(adminPIN: String, cashierPIN: String? = nil) throws -> DefaultPOSPINAuthenticator {
        let store = POSLocalPINStore(siteID: 123, storage: InMemoryPOSSecureStorage(), iterations: 1)
        try store.setPIN(adminPIN, for: .admin)
        if let cashierPIN {
            try store.setPIN(cashierPIN, for: .cashier)
        }
        return DefaultPOSPINAuthenticator(credentialProvider: store)
    }
}
