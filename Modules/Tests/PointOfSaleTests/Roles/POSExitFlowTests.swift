import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSExitFlowTests {
    @Test func test_request_when_cancelled_then_never_requests_approval_or_exits() throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let sut = POSExitFlow()
        var exits = 0

        // When
        sut.request(session: session)
        let request = try #require(sut.confirmation)
        #expect(sut.approvalHandler.request == nil)
        sut.cancelConfirmation()
        sut.confirm(request)
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }

        // Then
        #expect(exits == 0)
        #expect(sut.approvalHandler.request == nil)
        #expect(session.managerApprovalCapabilities.isEmpty)
    }

    @Test func test_confirm_when_authorized_then_exits_once_after_dialog_removal() throws {
        // Given
        for session: POSAccessSession in [MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff), UnrestrictedPOSAccessSession()] {
            let sut = POSExitFlow()
            var exits = 0
            sut.request(session: session)
            let request = try #require(sut.confirmation)

            // When
            sut.confirm(request)
            #expect(exits == 0)
            #expect(sut.confirmation == nil)
            sut.confirm(request)
            sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }
            sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }
            sut.request(session: session)

            // Then
            #expect(exits == 1)
            #expect(sut.approvalHandler.request == nil)
            #expect(sut.confirmation == nil)
        }
    }

    @Test func test_confirm_when_cashier_then_requires_approval_and_exits_once() async throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let sut = POSExitFlow()
        var exits = 0
        let request = try beginConfirmation(sut, session: session)

        // When
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }
        #expect(sut.approvalHandler.request?.capability == .exitPOS)
        #expect(exits == 0)
        _ = await sut.approvalHandler.submit(pin: "1234")
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }

        // Then
        #expect(exits == 1)
        #expect(session.currentStaff == POSLocalRole.cashier.staff)
        #expect(session.managerApprovalCapabilities == [.exitPOS])
    }

    @Test(arguments: [POSAuthError.invalidPIN, .unknown])
    func test_approval_when_failed_or_cancelled_then_can_start_a_new_exit(error: POSAuthError) async throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff, managerApprovalResult: .failure(error))
        let sut = POSExitFlow()
        var exits = 0
        let request = try beginConfirmation(sut, session: session)
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }

        // When
        #expect(await sut.approvalHandler.submit(pin: "9999") == false)
        #expect(exits == 0)
        sut.approvalHandler.cancel()
        sut.request(session: session)
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }

        // Then
        #expect(exits == 0)
        #expect(sut.confirmation != nil)
        #expect(sut.confirmation != request)
        #expect(sut.approvalHandler.request == nil)
        #expect(session.currentStaff == POSLocalRole.cashier.staff)
    }

    @Test func test_confirm_when_scope_changes_or_session_is_replaced_then_does_not_authorize_exit() throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff)
        let sut = POSExitFlow()
        var exits = 0
        let stale = try beginConfirmation(sut, session: session)

        // When
        session.endSession()
        sut.confirmationDismissed(stale, session: session, reason: "Exit") { exits += 1 }
        let replaced = try beginConfirmation(sut, session: session)
        sut.confirmationDismissed(replaced, session: UnrestrictedPOSAccessSession(), reason: "Exit") { exits += 1 }

        // Then
        #expect(exits == 0)
        #expect(sut.approvalHandler.request == nil)
    }

    @Test(arguments: [true, false])
    func test_approval_when_session_changes_during_verification_then_late_success_does_not_exit(locks: Bool) async throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let sut = POSExitFlow()
        var exits = 0
        let request = try beginConfirmation(sut, session: session)
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }
        session.onManagerApproval = {
            if locks { session.lock() } else { session.endSession() }
        }

        // When
        _ = await sut.approvalHandler.submit(pin: "1234")

        // Then
        #expect(exits == 0)
        #expect(sut.approvalHandler.request == nil)
    }

    @Test func test_cancel_when_approval_is_in_flight_then_late_success_does_not_exit() async throws {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let sut = POSExitFlow()
        var exits = 0
        let request = try beginConfirmation(sut, session: session)
        sut.confirmationDismissed(request, session: session, reason: "Exit") { exits += 1 }
        session.onManagerApproval = { sut.cancel() }

        // When
        _ = await sut.approvalHandler.submit(pin: "1234")

        // Then
        #expect(exits == 0)
        #expect(sut.confirmation == nil)
        #expect(sut.approvalHandler.request == nil)
    }

    private func beginConfirmation(_ sut: POSExitFlow, session: POSAccessSession) throws -> POSExitFlow.Confirmation {
        sut.request(session: session)
        let request = try #require(sut.confirmation)
        sut.confirm(request)
        return request
    }
}
