import Testing
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSPINAuthenticatorTests {
    @Test func test_authenticate_when_pin_is_known_then_returns_demo_staff() async throws {
        // Given
        let sut = DefaultPOSPINAuthenticator()

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then
        #expect(staff.role == "shop_manager")
        #expect(staff.capabilities == Set(POSCapability.allCases.map(\.rawValue)))
    }

    @Test func test_authenticate_when_pin_is_unknown_then_throws_invalidPIN() async throws {
        // Given
        let sut = DefaultPOSPINAuthenticator()

        // When / Then
        do {
            _ = try await sut.authenticate(withPIN: "9999")
            Issue.record("Expected invalidPIN error")
        } catch POSAuthError.invalidPIN {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func test_verify_when_called_then_throws_unknown() async throws {
        // Given
        let sut = DefaultPOSPINAuthenticator()

        // When / Then
        do {
            try await sut.verify(managerPIN: "1234", authorizes: .refundShopOrders)
            Issue.record("Expected unknown error")
        } catch POSAuthError.unknown {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func test_hasAnyPINs_when_called_then_returns_true() async throws {
        // Given
        let sut = DefaultPOSPINAuthenticator()

        // When
        let result = try await sut.hasAnyPINs()

        // Then
        #expect(result == true)
    }
}
