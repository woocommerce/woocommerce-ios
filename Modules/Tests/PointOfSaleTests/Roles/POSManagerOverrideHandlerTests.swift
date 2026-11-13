import Foundation
import Observation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSManagerOverrideHandlerTests {
    @Test func test_requestApproval_when_attempt_state_is_unreadable_then_keeps_input_disabled_without_comparison() async {
        // Given
        let session = MockPOSAccessSession(checkLockoutResult: .failure(.unknown))
        let sut = POSManagerOverrideHandler(session: session)

        // When
        let approval = await present(sut)

        // Then
        #expect(sut.pinEntryState == .unavailable)
        #expect(!POSPINEntryViewHelper().isInputEnabled(for: sut.pinEntryState))
        #expect(session.managerApprovalPINs.isEmpty)
        await cancel(sut, approval)
    }

    @Test func test_requestApproval_when_called_then_presents_request_and_resets_pin_state() async {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession(), initialPINEntryState: .error(kind: .invalidPIN))

        // When
        let approval = await present(sut, capability: .issueRefunds)

        // Then
        #expect(sut.request?.capability == .issueRefunds)
        #expect(sut.request?.reason == "Approval required")
        #expect(sut.pinEntryState == .idle)
        await cancel(sut, approval)
    }

    @Test func test_gate_when_session_grants_capability_then_performs_immediately_without_override() {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession(currentStaff: POSLocalRole.admin.staff))
        var viaOverride: Bool?

        // When
        sut.gate(.manageStoreSettings, reason: "Settings") { viaOverride = $0 }

        // Then
        #expect(viaOverride == false)
        #expect(sut.request == nil)
    }

    @Test func test_gate_when_roles_are_off_then_performs_immediately_without_override() {
        // Given
        let sut = POSManagerOverrideHandler(session: UnrestrictedPOSAccessSession())
        var count = 0

        // When
        sut.gate(.exitPOS, reason: "Exit") { viaOverride in
            #expect(!viaOverride)
            count += 1
        }

        // Then
        #expect(count == 1)
        #expect(sut.request == nil)
    }

    @Test func test_gate_when_session_is_missing_then_does_not_perform_or_present() {
        // Given
        let sut = POSManagerOverrideHandler()
        var count = 0

        // When
        sut.gate(.exitPOS, reason: "Exit") { _ in count += 1 }

        // Then
        #expect(count == 0)
        #expect(sut.request == nil)
    }

    @Test func test_gate_when_approval_succeeds_then_dismisses_and_performs_once() async {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let sut = POSManagerOverrideHandler(session: session)
        var count = 0

        // When
        await withCheckedContinuation { completion in
            sut.gate(.issueRefunds, reason: "Refund") { viaOverride in
                #expect(viaOverride)
                #expect(sut.request == nil)
                count += 1
                completion.resume()
            }
            #expect(sut.request?.capability == .issueRefunds)
            Task { #expect(await sut.submit(pin: "1234")) }
        }

        // Then
        #expect(count == 1)
        #expect(session.managerApprovalCapabilities == [.issueRefunds])
    }

    @Test func test_gate_when_cancelled_immediately_then_does_not_present_later() async {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession())
        var count = 0

        // When
        sut.gate(.issueRefunds, reason: "Refund") { _ in count += 1 }
        sut.cancel()
        let next = await present(sut)

        // Then
        #expect(sut.request?.capability == .manageStoreSettings)
        #expect(count == 0)
        await cancel(sut, next)
    }

    @Test func test_gate_when_approved_then_performs_in_verification_task_without_result_relay() async {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSLocalRole.cashier.staff)
        let sut = POSManagerOverrideHandler(session: session)
        var verificationTaskID: Int?
        session.onManagerApproval = {
            withUnsafeCurrentTask { verificationTaskID = $0?.hashValue }
        }

        // When
        await withCheckedContinuation { completion in
            sut.gate(.issueRefunds, reason: "Refund") { viaOverride in
                // Then
                #expect(viaOverride)
                #expect(sut.request == nil)
                withUnsafeCurrentTask { #expect($0?.hashValue == verificationTaskID) }
                completion.resume()
            }
            Task { #expect(await sut.submit(pin: "1234")) }
        }
        #expect(verificationTaskID != nil)
        #expect(session.managerApprovalCapabilities == [.issueRefunds])
    }

    @Test func test_submit_when_started_then_keeps_loading_during_verification() async {
        // Given
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        let approval = await present(sut)
        session.onManagerApproval = { #expect(sut.pinEntryState == .loading) }

        // When
        #expect(await sut.submit(pin: "1234"))

        // Then
        #expect(await approval.value == .completed)
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_submit_when_pin_is_invalid_then_keeps_request_for_retry() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN))
        let sut = POSManagerOverrideHandler(session: session)
        let approval = await present(sut, capability: .issueRefunds)

        // When
        #expect(await sut.submit(pin: "9999") == false)

        // Then
        #expect(session.managerApprovalPINs == ["9999"])
        #expect(session.managerApprovalCapabilities == [.issueRefunds])
        #expect(sut.pinEntryState == .error(kind: .invalidPIN))
        #expect(sut.request != nil)
        session.managerApprovalResult = .success(())
        #expect(await sut.submit(pin: "1234"))
        #expect(await approval.value == .completed)
    }

    @Test func test_submit_when_error_is_unknown_then_keeps_input_unavailable() async {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession(managerApprovalResult: .failure(.unknown)))
        let approval = await present(sut)

        // When
        #expect(await sut.submit(pin: "1234") == false)

        // Then
        #expect(sut.pinEntryState == .unavailable)
        await cancel(sut, approval)
    }

    @Test func test_submit_when_session_is_missing_then_keeps_input_unavailable() async {
        // Given
        let sut = POSManagerOverrideHandler()
        let approval = await present(sut)

        // When
        #expect(await sut.submit(pin: "1234") == false)

        // Then
        #expect(sut.pinEntryState == .unavailable)
        await cancel(sut, approval)
    }

    @Test func test_cancel_when_request_has_error_then_returns_cancelled_without_verifying_again() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN))
        let sut = POSManagerOverrideHandler(session: session)
        let approval = await present(sut)
        #expect(await sut.submit(pin: "9999") == false)

        // When
        await cancel(sut, approval)

        // Then
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(session.managerApprovalPINs == ["9999"])
    }

    @Test func test_requestApproval_when_caller_is_cancelled_before_entry_then_does_not_replace_request() async {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession())
        let first = await present(sut)
        let firstID = sut.request?.id
        let cancelled = Task { await sut.requestApproval(for: .issueRefunds, reason: "Stale") }

        // When
        cancelled.cancel()

        // Then
        #expect(await cancelled.value == .cancelled)
        #expect(sut.request?.id == firstID)
        await cancel(sut, first)
    }

    @Test func test_requestApproval_when_caller_is_cancelled_while_waiting_then_dismisses() async {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession())
        let approval = await present(sut)

        // When
        approval.cancel()

        // Then
        #expect(await approval.value == .cancelled)
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
    }

    @Test(arguments: [false, true], [false, true])
    func test_submission_when_cancelled_or_replaced_then_returns_cancelled_without_pin_failure(custom: Bool, replace: Bool) async {
        // Given
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        var replacement: Task<POSManagerOverrideHandler.ApprovalResult, Never>?
        let change: @MainActor () async -> Void = {
            if replace {
                replacement = await present(sut, capability: .createCoupons)
            } else {
                sut.cancel()
            }
        }
        let operation: POSManagerOverrideHandler.PINOperation? = custom ? { _ in await change(); return true } : nil
        let approval = await present(sut, operation: operation)
        if !custom { session.onManagerApproval = change }

        // When
        #expect(await sut.submit(pin: "1234"))

        // Then
        #expect(await approval.value == .cancelled)
        #expect(sut.pinEntryState == .idle)
        if let replacement {
            #expect(sut.request?.capability == .createCoupons)
            session.onManagerApproval = nil
            #expect(await sut.submit(pin: "1234"))
            #expect(await replacement.value == .completed)
        } else {
            #expect(sut.request == nil)
        }
    }

    @Test func test_custom_submission_when_cancelled_before_error_returns_then_does_not_publish_error() async {
        // Given
        let sut = POSManagerOverrideHandler()
        let approval = await present(sut, operation: { _ throws(POSAuthError) in
            sut.cancel()
            throw .invalidPIN
        })

        // When
        #expect(await sut.submit(pin: "1234"))

        // Then
        #expect(await approval.value == .cancelled)
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_custom_submission_when_save_fails_then_stays_open_until_retry_succeeds() async {
        // Given
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        var saved = false
        let approval = await present(sut, operation: { _ in
            #expect(sut.pinEntryState == .loading)
            return saved
        })

        // When
        #expect(await sut.submit(pin: "1234") == false)

        // Then
        #expect(sut.request != nil)
        #expect(sut.pinEntryState == .error(kind: .generic))
        #expect(session.managerApprovalPINs.isEmpty)
        saved = true
        #expect(await sut.submit(pin: "1234"))
        #expect(await approval.value == .completed)
    }

    @Test func test_custom_submission_when_another_pin_is_submitted_then_rejects_duplicate() async {
        // Given
        let sut = POSManagerOverrideHandler()
        var count = 0
        let approval = await present(sut, operation: { _ in
            count += 1
            #expect(await sut.submit(pin: "5678") == false)
            return true
        })

        // When
        #expect(await sut.submit(pin: "1234"))

        // Then
        #expect(count == 1)
        #expect(await approval.value == .completed)
    }

    @Test func test_custom_submission_when_caller_cancels_during_operation_then_operation_observes_cancellation() async {
        // Given
        let sut = POSManagerOverrideHandler()
        var approval: Task<POSManagerOverrideHandler.ApprovalResult, Never>?
        approval = await present(sut, operation: { _ in
            approval?.cancel()
            #expect(Task.isCancelled)
            return true
        })

        // When
        #expect(await sut.submit(pin: "1234"))

        // Then
        #expect(await approval?.value == .cancelled)
        #expect(sut.request == nil)
    }

    @Test(arguments: [false, true])
    func test_submit_when_rate_limited_then_preserves_deadline_and_disables_input(custom: Bool) async {
        // Given
        let seconds = 30
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.rateLimited(remainingSeconds: seconds)))
        let sut = POSManagerOverrideHandler(session: session)
        let operation: POSManagerOverrideHandler.PINOperation? = custom ? { _ throws(POSAuthError) in
            throw .rateLimited(remainingSeconds: seconds)
        } : nil
        let approval = await present(sut, operation: operation)

        // When
        #expect(await sut.submit(pin: "0000") == false)

        // Then
        #expect(sut.pinEntryState == .waiting(remainingSeconds: seconds))
        #expect(POSPINEntryViewHelper().isInputEnabled(for: sut.pinEntryState) == false)
        await cancel(sut, approval)
    }

    @Test func test_requestApproval_when_shared_wait_is_active_then_shows_countdown_without_pin_submission() async {
        // Given
        let seconds = 30
        let session = MockPOSAccessSession(checkLockoutResult: .failure(.rateLimited(remainingSeconds: seconds)))
        let sut = POSManagerOverrideHandler(session: session)

        // When
        let approval = await present(sut)

        // Then
        #expect(sut.pinEntryState == .waiting(remainingSeconds: seconds))
        #expect(session.managerApprovalPINs.isEmpty)
        await cancel(sut, approval)
    }

    @Test func test_configure_when_request_precedes_session_then_restores_shared_wait() async {
        // Given
        let seconds = 30
        let session = MockPOSAccessSession(checkLockoutResult: .failure(.rateLimited(remainingSeconds: seconds)))
        let sut = POSManagerOverrideHandler()
        let approval = await present(sut)

        // When
        sut.configure(session: session)
        await waitUntilReady(sut)

        // Then
        #expect(sut.pinEntryState == .waiting(remainingSeconds: seconds))
        await cancel(sut, approval)
    }

    @Test func test_configure_when_request_has_pin_error_then_preserves_feedback() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN))
        let sut = POSManagerOverrideHandler(session: session)
        let approval = await present(sut)
        #expect(await sut.submit(pin: "0000") == false)

        // When
        sut.configure(session: session)

        // Then
        #expect(sut.pinEntryState == .error(kind: .invalidPIN))
        await cancel(sut, approval)
    }

    @Test func test_lockoutExpired_when_wait_remains_then_rechecks_before_enabling_input() async {
        // Given
        let seconds = 30
        let session = MockPOSAccessSession(checkLockoutResult: .failure(.rateLimited(remainingSeconds: seconds)))
        let sut = POSManagerOverrideHandler(session: session)
        let approval = await present(sut)

        // When
        await sut.lockoutExpired()

        // Then
        #expect(sut.pinEntryState == .waiting(remainingSeconds: seconds))
        session.checkLockoutResult = .success(())
        await sut.lockoutExpired()
        #expect(sut.pinEntryState == .idle)
        await cancel(sut, approval)
    }

    @Test func test_lockoutExpired_when_new_submission_is_loading_then_does_not_clear_loading() async {
        // Given
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        let approval = await present(sut)
        session.onManagerApproval = {
            // When
            await sut.lockoutExpired()
            // Then
            #expect(sut.pinEntryState == .loading)
        }

        #expect(await sut.submit(pin: "1234"))
        #expect(await approval.value == .completed)
    }

    private func present(_ sut: POSManagerOverrideHandler,
                         capability: POSCapability = .manageStoreSettings,
                         operation: POSManagerOverrideHandler.PINOperation? = nil) async -> Task<POSManagerOverrideHandler.ApprovalResult, Never> {
        let approval = Task { await sut.requestApproval(for: capability, reason: "Approval required", operation: operation) }
        await withCheckedContinuation { ready in
            withObservationTracking { _ = sut.request } onChange: {
                Task { @MainActor in ready.resume() }
            }
        }
        await waitUntilReady(sut)
        return approval
    }

    private func waitUntilReady(_ sut: POSManagerOverrideHandler) async {
        guard sut.pinEntryState == .loading else { return }
        await withCheckedContinuation { ready in
            withObservationTracking { _ = sut.pinEntryState } onChange: {
                Task { @MainActor in ready.resume() }
            }
        }
    }

    private func cancel(_ sut: POSManagerOverrideHandler, _ approval: Task<POSManagerOverrideHandler.ApprovalResult, Never>) async {
        sut.cancel()
        #expect(await approval.value == .cancelled)
    }
}
