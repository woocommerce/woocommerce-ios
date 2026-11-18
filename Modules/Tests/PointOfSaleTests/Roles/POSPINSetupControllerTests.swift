import Testing
@testable import PointOfSale

@MainActor
struct POSPINSetupControllerTests {
    @Test func test_first_entry_when_validation_fails_then_rejects_without_confirmation_or_save() async {
        // Given
        var saved = false
        let controller = POSPINSetupController(validatePIN: { _ in throw POSPINStoreError.pinMatchesOtherRole }) { _ in
            saved = true
            return true
        }

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .rejected)
        #expect(controller.error == .pinMatchesOtherRole)
        #expect(!controller.isSaving)
        #expect(!saved)
    }

    @Test(arguments: [false, true])
    func test_validation_when_draft_is_discarded_then_late_result_does_not_restore_input_or_error(fails: Bool) async {
        // Given
        weak var validatingController: POSPINSetupController?
        let controller = POSPINSetupController(validatePIN: { _ in
            validatingController?.discardDraft()
            if fails { throw POSPINStoreError.pinMatchesOtherRole }
        }) { _ in Issue.record("Discarded validation must not save"); return true }
        validatingController = controller

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .rejected)
        #expect(controller.error == nil)
        #expect(!controller.isSaving)
    }

    @Test func test_validation_when_pending_then_reentry_is_rejected() async {
        // Given
        weak var validatingController: POSPINSetupController?
        let controller = POSPINSetupController(validatePIN: { _ in
            let current = try #require(validatingController)
            #expect(current.isSaving)
            #expect(await current.submit("5678") == .rejected)
        }) { _ in true }
        validatingController = controller

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .confirmationRequired)
        #expect(!controller.isSaving)
    }

    @Test func test_first_entry_when_submitted_then_requires_confirmation_without_saving() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController(validatePIN: { _ in }) { savedPINs.append($0); return true }

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .confirmationRequired)
        #expect(savedPINs.isEmpty)
    }

    @Test func test_confirmation_when_matching_then_saves_once_and_clears_draft() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController(validatePIN: { _ in }) { savedPINs.append($0); return true }
        _ = await controller.submit("1234")

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .saved)
        #expect(savedPINs == ["1234"])
        #expect(!controller.isSaving)
    }

    @Test func test_mismatch_when_retried_then_requires_two_new_matching_entries() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController(validatePIN: { _ in }) { savedPINs.append($0); return true }
        _ = await controller.submit("1234")

        // When
        #expect(await controller.submit("5678") == .rejected)

        // Then
        #expect(savedPINs.isEmpty)
        #expect(await controller.submit("2468") == .confirmationRequired)
        #expect(savedPINs.isEmpty)
        #expect(await controller.submit("2468") == .saved)
        #expect(savedPINs == ["2468"])
    }

    @Test func test_save_when_rejected_then_starts_a_fresh_attempt_without_success() async {
        // Given
        let controller = POSPINSetupController(validatePIN: { _ in }) { _ in false }
        _ = await controller.submit("1234")

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .rejected)
        #expect(!controller.isSaving)
        #expect(await controller.submit("5678") == .confirmationRequired)
    }

    @Test func test_discard_when_confirming_then_discards_input_without_saving() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController(validatePIN: { _ in }) { savedPINs.append($0); return true }
        _ = await controller.submit("1234")

        // When
        controller.discardDraft()

        // Then
        #expect(savedPINs.isEmpty)
        #expect(await controller.submit("5678") == .confirmationRequired)
    }

    @Test func test_submit_when_already_saving_then_rejects_reentry() async {
        // Given
        weak var savingController: POSPINSetupController?
        let controller = POSPINSetupController(validatePIN: { _ in }) { _ in
            guard let savingController else { return false }
            #expect(savingController.isSaving)
            #expect(await savingController.submit("5678") == .rejected)
            return true
        }
        savingController = controller
        _ = await controller.submit("1234")

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .saved)
        #expect(!controller.isSaving)
    }

    @Test func test_discard_when_mismatched_then_clears_all_draft_state() async {
        // Given
        let controller = POSPINSetupController(validatePIN: { _ in }) { _ in true }
        _ = await controller.submit("1234")
        _ = await controller.submit("5678")

        // When
        controller.discardDraft()

        // Then
        #expect(await controller.submit("2468") == .confirmationRequired)
    }
}
