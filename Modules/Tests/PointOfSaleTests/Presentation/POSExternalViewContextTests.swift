import SwiftUI
import Testing
@testable import PointOfSale

@MainActor
struct POSExternalViewContextTests {
    @Test(arguments: POSLocalRole.allCases)
    func test_web_sign_in_when_protected_then_only_store_settings_capability_allows_app_session(role: POSLocalRole) {
        // Given
        let session = MockPOSAccessSession(currentStaff: role.staff)
        let sut = POSExternalViewContext(session: session)

        // Then
        #expect(sut.requiresEmbeddedSettingsWebView)
        #expect(sut.canReuseAppWebSignIn == (role == .admin))
    }

    @Test func test_web_sign_in_when_unprotected_then_app_session_is_allowed() {
        // Given
        let sut = POSExternalViewContext(session: UnrestrictedPOSAccessSession())

        // Then
        #expect(!sut.requiresEmbeddedSettingsWebView)
        #expect(sut.canReuseAppWebSignIn)
    }

    @Test func test_external_callback_when_lock_and_unlock_replace_scope_then_only_new_callback_runs() async throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let sut = POSExternalViewContext(session: session)
        var selections: [Int] = []
        let oldSelection = sut.whileSessionIsCurrent { selections.append($0) }

        // When
        session.lock()
        oldSelection(1)
        #expect(!sut.canReuseAppWebSignIn)
        try await session.signIn(withPIN: "1234")
        oldSelection(2)
        let newSelection = sut.whileSessionIsCurrent { selections.append($0) }
        newSelection(3)

        // Then
        #expect(selections == [3])
    }

    @Test func test_external_binding_when_session_ends_then_ignores_late_write() {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let sut = POSExternalViewContext(session: session)
        var isPresented = true
        let binding = sut.whileSessionIsCurrent(Binding(get: { isPresented }, set: { isPresented = $0 }))

        // When
        session.endSession()
        binding.wrappedValue = false

        // Then
        #expect(isPresented)
    }
}
