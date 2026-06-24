import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSManagerOverrideHandlerTests {
    @Test func test_requestApproval_when_called_then_presents_request_and_resets_pin_state() {
        // Given
        let sut = POSManagerOverrideHandler(
            session: MockPOSAccessSession(),
            initialPINEntryState: .error(kind: .invalidPIN)
        )

        // When
        sut.requestApproval(
            for: .issueRefunds,
            reason: "Refunding orders requires manager approval"
        )

        // Then
        #expect(sut.request?.capability == .issueRefunds)
        #expect(sut.request?.reason == "Refunding orders requires manager approval")
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_gate_when_session_grants_capability_then_performs_immediately_without_override() {
        // Given an operator who already holds the capability
        let manager = POSStaff(userID: 1, displayName: "Manny", preset: .manager,
                               capabilities: [POSCapability.issueRefunds.rawValue])
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession(currentStaff: manager))
        var performCount = 0
        var capturedApprover: POSStaff?

        // When
        sut.gate(.issueRefunds, reason: "Refunding orders requires manager approval") { approver in
            performCount += 1
            capturedApprover = approver
        }

        // Then it runs directly with no approver and presents no modal
        #expect(performCount == 1)
        #expect(capturedApprover == nil)
        #expect(sut.request == nil)
    }

    @Test func test_gate_when_session_denies_capability_then_presents_override_and_performs_on_approval() async {
        // Given an operator who lacks the capability and a manager who can authorize it
        let cashier = POSStaff(userID: 1, displayName: "Cassie", preset: .cashier,
                               capabilities: [POSCapability.processSales.rawValue])
        let approver = POSStaff(userID: 2, displayName: "Morgan", preset: .manager,
                                capabilities: Set(POSCapability.allCases.map(\.rawValue)))
        let session = MockPOSAccessSession(currentStaff: cashier, managerApprovalResult: .success(approver))
        let sut = POSManagerOverrideHandler(session: session)
        var performCount = 0
        var capturedApprover: POSStaff?

        // When the gate is requested for a capability the operator lacks
        sut.gate(.issueRefunds, reason: "Refunding orders requires manager approval") { approver in
            performCount += 1
            capturedApprover = approver
        }

        // Then the override modal is presented and the action has not run yet
        #expect(sut.request?.capability == .issueRefunds)
        #expect(performCount == 0)

        // When an authorized manager approves
        await sut.submit(pin: "1234")

        // Then the action runs, attributed to the approver
        #expect(performCount == 1)
        #expect(capturedApprover == approver)
    }

    @Test func test_submit_when_started_then_sets_loading_state() async {
        // Given
        var loadingStateObserved = false
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .createCoupons, reason: "Creating coupons requires manager approval")
        session.onManagerApproval = {
            if sut.pinEntryState == .loading {
                loadingStateObserved = true
            }
        }

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(loadingStateObserved)
        #expect(session.managerApprovalPINs == ["1234"])
    }

    @Test func test_submit_when_pin_is_valid_then_requests_approval_dismisses_and_runs_completion() async {
        // Given
        let approver = POSStaff(userID: 88,
                                displayName: "Morgan",
                                preset: .manager,
                                capabilities: Set(POSCapability.allCases.map(\.rawValue)))
        var completionWasCalled = false
        var completionApprover: POSStaff?
        let session = MockPOSAccessSession(managerApprovalResult: .success(approver))
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(
            for: .viewPOSSettings,
            reason: "Viewing settings requires manager approval",
            onApproved: { approvedStaff in
                completionWasCalled = true
                completionApprover = approvedStaff
            }
        )

        // When
        let succeeded = await sut.submit(pin: "1234")

        // Then
        #expect(succeeded == true)
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(session.managerApprovalCapabilities == [.viewPOSSettings])
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(completionWasCalled)
        #expect(completionApprover == approver)
    }

    @Test func test_submit_when_pin_is_invalid_then_shows_invalid_pin_error() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN))
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .issueRefunds, reason: "Refunding orders requires manager approval")

        // When
        let succeeded = await sut.submit(pin: "9999")

        // Then
        #expect(succeeded == false)
        #expect(session.managerApprovalPINs == ["9999"])
        #expect(session.managerApprovalCapabilities == [.issueRefunds])
        #expect(sut.request?.capability == .issueRefunds)
        #expect(sut.pinEntryState == .error(kind: .invalidPIN))
    }

    @Test func test_submit_when_error_is_unknown_then_shows_generic_error() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.unknown))
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .createCoupons, reason: "Creating coupons requires manager approval")

        // When
        let succeeded = await sut.submit(pin: "1234")

        // Then
        #expect(succeeded == false)
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(sut.request?.capability == .createCoupons)
        #expect(sut.pinEntryState == .error(kind: .generic))
    }

    @Test func test_cancel_when_request_is_presented_with_error_then_dismisses_without_calling_session_again() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN))
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .editPOSSettings, reason: "Editing settings requires manager approval")
        await sut.submit(pin: "9999")

        // When
        sut.cancel()

        // Then
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(session.managerApprovalPINs == ["9999"])
        #expect(session.managerApprovalCapabilities == [.editPOSSettings])
    }

    @Test func test_submit_when_request_replaced_in_flight_then_neither_completion_is_called() async {
        // Given
        var firstCompletionWasCalled = false
        var secondCompletionWasCalled = false
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(
            for: .issueRefunds,
            reason: "Refunding orders requires manager approval",
            onApproved: { _ in
                firstCompletionWasCalled = true
            }
        )
        session.onManagerApproval = {
            sut.requestApproval(
                for: .createCoupons,
                reason: "Creating coupons requires manager approval",
                onApproved: { _ in
                    secondCompletionWasCalled = true
                }
            )
        }

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(session.managerApprovalCapabilities == [.issueRefunds])
        #expect(sut.request?.capability == .createCoupons)
        #expect(sut.pinEntryState == .idle)
        #expect(firstCompletionWasCalled == false)
        #expect(secondCompletionWasCalled == false)
    }

    @Test func test_submit_when_cancelled_in_flight_then_completion_is_not_called() async {
        // Given
        var completionWasCalled = false
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(
            for: .issueRefunds,
            reason: "Refunding orders requires manager approval",
            onApproved: { _ in
                completionWasCalled = true
            }
        )
        session.onManagerApproval = {
            sut.cancel()
        }

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(session.managerApprovalCapabilities == [.issueRefunds])
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(completionWasCalled == false)
    }

    @Test func test_requestApproval_when_called_consecutively_then_replaces_previous_request_and_completion() async {
        // Given
        var firstCompletionWasCalled = false
        var secondCompletionWasCalled = false
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(
            for: .issueRefunds,
            reason: "Refunding orders requires manager approval",
            onApproved: { _ in
                firstCompletionWasCalled = true
            }
        )
        let firstRequestID = sut.request?.id

        // When
        sut.requestApproval(
            for: .createCoupons,
            reason: "Creating coupons requires manager approval",
            onApproved: { _ in
                secondCompletionWasCalled = true
            }
        )
        let secondRequest = sut.request
        await sut.submit(pin: "1234")

        // Then
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(secondRequest?.id != firstRequestID)
        #expect(secondRequest?.capability == .createCoupons)
        #expect(secondRequest?.reason == "Creating coupons requires manager approval")
        #expect(session.managerApprovalCapabilities == [.createCoupons])
        #expect(firstCompletionWasCalled == false)
        #expect(secondCompletionWasCalled)
    }

    @Test func test_submit_when_session_is_missing_then_shows_generic_error() async {
        // Given
        let sut = POSManagerOverrideHandler()
        sut.requestApproval(for: .issueRefunds, reason: "Refunding orders requires manager approval")

        // When
        let succeeded = await sut.submit(pin: "1234")

        // Then
        #expect(succeeded == false)
        #expect(sut.request?.capability == .issueRefunds)
        #expect(sut.pinEntryState == .error(kind: .generic))
    }
}
