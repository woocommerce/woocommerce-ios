import Testing
@testable import PointOfSale

@MainActor
struct POSSecurityPINPresentationTests {
    @Test func test_guide_when_presented_and_closed_then_never_restores_pin_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        sut.present(.editor(makeEditor()))

        // When
        sut.present(.guidedAccessGuide)
        sut.finishApproval(editor: makeEditor())

        // Then
        #expect(sut.destination == .guidedAccessGuide)
        #expect(sut.destination?.compactStyle == .fullScreen(title: POSGuidedAccessGuideView.Localization.title))
        sut.cancel()
        #expect(sut.destination == nil)
    }

    @Test(arguments: [POSPINSetupFlow.Configuration.initialAdmin, .adminChange, .cashier])
    func test_editor_when_presented_then_leaves_title_in_content(configuration: POSPINSetupFlow.Configuration) {
        // Given
        let editor = makeEditor(configuration: configuration)

        // When
        let style = POSSecurityPINPresentation.Destination.editor(editor).compactStyle

        // Then
        #expect(style == .fullScreen(title: ""))
    }

    @Test func test_approval_when_presented_then_keeps_approval_header() {
        // When
        let style = makeApproval().compactStyle

        // Then
        #expect(style == .managerApproval)
    }

    @Test(arguments: [false, true])
    func test_handoff_when_waiting_for_result_or_dismissal_then_blocks_settings(dismissesFirst: Bool) {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        #expect(!sut.isTransitioning)
        sut.present(approval)
        #expect(!sut.isTransitioning)

        // When
        sut.approvalEnded()
        #expect(sut.isTransitioning)
        if dismissesFirst {
            sut.dismissalCompleted(for: approval)
            #expect(sut.isTransitioning)
            sut.finishApproval(editor: makeEditor())
        } else {
            sut.finishApproval(editor: makeEditor())
            #expect(sut.isTransitioning)
            sut.dismissalCompleted(for: approval)
        }

        // Then
        #expect(!sut.isTransitioning)
    }

    @Test func test_handoff_when_cancelled_then_unblocks_settings() {
        // Given
        let sut = POSSecurityPINPresentation()
        sut.present(makeApproval())
        sut.approvalEnded()

        // When
        sut.cancel()

        // Then
        #expect(!sut.isTransitioning)
    }

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

    @Test(arguments: [false, true])
    func test_approval_when_request_ends_before_result_then_opens_only_after_result_and_dismissal(dismissesFirst: Bool) {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        let editor = makeEditor()
        sut.present(approval)

        // When
        sut.approvalEnded()
        #expect(sut.destination == nil)
        if dismissesFirst {
            sut.dismissalCompleted(for: approval)
            #expect(sut.destination == nil)
            sut.finishApproval(editor: editor)
        } else {
            sut.finishApproval(editor: editor)
            #expect(sut.destination == nil)
            sut.dismissalCompleted(for: approval)
        }

        // Then
        #expect(sut.destination == .editor(editor))
    }

    @Test func test_pending_approval_when_cancelled_then_closes_before_worker_finishes() {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        sut.present(approval)

        // When
        sut.approvalEnded()

        // Then
        #expect(sut.destination == nil)
        sut.dismissalCompleted(for: approval)
        sut.finishApproval(editor: nil)
        #expect(sut.destination == nil)
    }

    @Test func test_dismissed_approval_when_settings_closes_then_late_worker_cannot_reopen_editor() {
        // Given
        let sut = POSSecurityPINPresentation()
        let approval = makeApproval()
        sut.present(approval)
        sut.approvalEnded()
        sut.dismissalCompleted(for: approval)

        // When
        sut.cancel()
        sut.finishApproval(editor: makeEditor())

        // Then
        #expect(sut.destination == nil)
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
