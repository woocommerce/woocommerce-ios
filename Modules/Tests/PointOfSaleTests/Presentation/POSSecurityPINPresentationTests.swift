import Testing
@testable import PointOfSale

@MainActor
struct POSSecurityPINPresentationTests {
    @Test func test_approval_when_completed_then_waits_for_dismissal_before_presenting_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        let editor = makeEditor()
        sut.present(approval)

        // When
        sut.finishApproval(editor: editor)

        // Then
        #expect(sut.destination == nil)
        sut.dismissalCompleted(for: approval)
        #expect(sut.destination == .editor(editor))
        sut.dismissalCompleted(for: approval)
        #expect(sut.destination == .editor(editor))
    }

    @Test func test_approval_when_cancelled_then_dismissal_does_not_open_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        sut.present(approval)

        // When
        sut.finishApproval(editor: nil)
        sut.dismissalCompleted(for: approval)

        // Then
        #expect(sut.destination == nil)
    }

    @Test func test_handoff_when_cancelled_then_late_dismissal_cannot_reopen_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        sut.present(approval)
        sut.finishApproval(editor: makeEditor())

        // When
        sut.cancel()
        sut.dismissalCompleted(for: approval)

        // Then
        #expect(sut.destination == nil)
    }

    @Test func test_handoff_when_new_approval_replaces_it_then_old_completion_cannot_open_either_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        let oldApproval = makeApproval()
        let newApproval = makeApproval()
        let editor = makeEditor()
        sut.present(oldApproval)
        sut.finishApproval(editor: makeEditor())
        sut.present(newApproval)

        // When
        sut.dismissalCompleted(for: oldApproval)

        // Then
        #expect(sut.destination == newApproval)
        sut.finishApproval(editor: editor)
        sut.dismissalCompleted(for: oldApproval)
        #expect(sut.destination == nil)
        sut.dismissalCompleted(for: newApproval)
        #expect(sut.destination == .editor(editor))
    }

    @Test func test_handoff_when_direct_editor_replaces_it_then_old_dismissal_keeps_new_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        sut.present(approval)
        sut.finishApproval(editor: makeEditor())
        let directEditor = makeEditor(configuration: .cashier)

        // When
        sut.present(.editor(directEditor))
        sut.dismissalCompleted(for: approval)

        // Then
        #expect(sut.destination == .editor(directEditor))
    }

    @Test func test_approval_when_result_arrives_after_cancel_then_does_not_present_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        sut.present(makeApproval())
        sut.cancel()

        // When
        sut.finishApproval(editor: makeEditor())

        // Then
        #expect(sut.destination == nil)
    }

    @Test(arguments: [POSPINSetupFlow.Configuration.initialAdmin, .cashier])
    func test_direct_setup_when_presented_then_opens_without_waiting_for_dismissal(configuration: POSPINSetupFlow.Configuration) {
        // Given
        let sut = POSSecurityPINPresentation()
        let editor = makeEditor(configuration: configuration)

        // When
        sut.present(.editor(editor))

        // Then
        #expect(sut.destination == .editor(editor))
    }

    private func makeApproval() -> POSSecurityPINPresentation.Destination {
        .approval(POSManagerOverrideRequest(capability: .manageStoreSettings, reason: "Change Admin PIN"))
    }

    private func makeEditor(configuration: POSPINSetupFlow.Configuration = .adminChange) -> POSPINSetupFlow {
        POSPINSetupFlow(configuration: configuration,
                        setup: POSPINSetupController(validatePIN: { _ in }, savePIN: { _ in true }),
                        sleep: { _ in })
    }
}
