import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSManagerOverrideHandlerTests {
    @Test func test_requestApproval_when_called_then_presents_request_and_resets_pin_state() {
        // Given
        let sut = POSManagerOverrideHandler(session: MockPOSAccessSession())
        sut.pinEntryState = .error(message: "Previous error")

        // When
        sut.requestApproval(
            for: .refundShopOrders,
            reason: "Refunding orders requires manager approval"
        )

        // Then
        #expect(sut.request?.capability == .refundShopOrders)
        #expect(sut.request?.reason == "Refunding orders requires manager approval")
        #expect(sut.pinEntryState == .idle)
    }

    @Test func test_submit_when_started_then_sets_loading_state() async {
        // Given
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .publishShopCoupons, reason: "Creating coupons requires manager approval")
        session.onManagerApproval = {
            #expect(sut.pinEntryState == .loading)
        }

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(session.managerApprovalPINs == ["1234"])
    }

    @Test func test_submit_when_pin_is_valid_then_requests_approval_dismisses_and_runs_completion() async {
        // Given
        var completionWasCalled = false
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(
            for: .viewPOSSettings,
            reason: "Viewing settings requires manager approval",
            onApproved: {
                completionWasCalled = true
            }
        )

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(session.managerApprovalCapabilities == [.viewPOSSettings])
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(completionWasCalled)
    }

    @Test func test_submit_when_pin_is_invalid_then_shows_invalid_pin_error() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN))
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .refundShopOrders, reason: "Refunding orders requires manager approval")

        // When
        await sut.submit(pin: "9999")

        // Then
        #expect(session.managerApprovalPINs == ["9999"])
        #expect(session.managerApprovalCapabilities == [.refundShopOrders])
        #expect(sut.request?.capability == .refundShopOrders)
        #expect(sut.pinEntryState == .error(message: "Incorrect PIN. Try again."))
    }

    @Test func test_submit_when_error_is_unknown_then_shows_generic_error() async {
        // Given
        let session = MockPOSAccessSession(managerApprovalResult: .failure(.unknown))
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .publishShopCoupons, reason: "Creating coupons requires manager approval")

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(session.managerApprovalPINs == ["1234"])
        #expect(sut.request?.capability == .publishShopCoupons)
        #expect(sut.pinEntryState == .error(message: "Something went wrong. Try again."))
    }

    @Test func test_cancel_when_request_is_presented_then_dismisses_without_calling_session() {
        // Given
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(for: .editPOSSettings, reason: "Editing settings requires manager approval")
        sut.pinEntryState = .error(message: "Incorrect PIN. Try again.")

        // When
        sut.cancel()

        // Then
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(session.managerApprovalPINs.isEmpty)
        #expect(session.managerApprovalCapabilities.isEmpty)
    }

    @Test func test_submit_when_cancelled_in_flight_then_completion_is_not_called() async {
        // Given
        var completionWasCalled = false
        let session = MockPOSAccessSession()
        let sut = POSManagerOverrideHandler(session: session)
        sut.requestApproval(
            for: .refundShopOrders,
            reason: "Refunding orders requires manager approval",
            onApproved: {
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
        #expect(session.managerApprovalCapabilities == [.refundShopOrders])
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
            for: .refundShopOrders,
            reason: "Refunding orders requires manager approval",
            onApproved: {
                firstCompletionWasCalled = true
            }
        )
        let firstRequestID = sut.request?.id
        sut.pinEntryState = .error(message: "Previous error")

        // When
        sut.requestApproval(
            for: .publishShopCoupons,
            reason: "Creating coupons requires manager approval",
            onApproved: {
                secondCompletionWasCalled = true
            }
        )
        let secondRequest = sut.request
        await sut.submit(pin: "1234")

        // Then
        #expect(sut.request == nil)
        #expect(sut.pinEntryState == .idle)
        #expect(firstRequestID != nil)
        #expect(secondRequest?.id != firstRequestID)
        #expect(secondRequest?.capability == .publishShopCoupons)
        #expect(secondRequest?.reason == "Creating coupons requires manager approval")
        #expect(session.managerApprovalCapabilities == [.publishShopCoupons])
        #expect(firstCompletionWasCalled == false)
        #expect(secondCompletionWasCalled)
    }

    @Test func test_submit_when_session_is_missing_then_shows_generic_error() async {
        // Given
        let sut = POSManagerOverrideHandler()
        sut.requestApproval(for: .refundShopOrders, reason: "Refunding orders requires manager approval")

        // When
        await sut.submit(pin: "1234")

        // Then
        #expect(sut.request?.capability == .refundShopOrders)
        #expect(sut.pinEntryState == .error(message: "Something went wrong. Try again."))
    }
}
