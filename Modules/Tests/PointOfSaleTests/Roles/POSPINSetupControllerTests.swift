import Testing
@testable import PointOfSale

@MainActor
struct POSPINSetupControllerTests {
    @Test func test_first_entry_when_submitted_then_requires_confirmation_without_saving() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController { savedPINs.append($0); return true }

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .confirmationRequired)
        #expect(controller.isConfirmingPIN)
        #expect(!controller.hasMismatch)
        #expect(savedPINs.isEmpty)
    }

    @Test func test_confirmation_when_matching_then_saves_once_and_clears_draft() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController { savedPINs.append($0); return true }
        _ = await controller.submit("1234")

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .saved)
        #expect(savedPINs == ["1234"])
        #expect(!controller.isConfirmingPIN)
        #expect(!controller.isSaving)
    }

    @Test func test_mismatch_when_retried_then_requires_two_new_matching_entries() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController { savedPINs.append($0); return true }
        _ = await controller.submit("1234")

        // When
        #expect(await controller.submit("5678") == .rejected)

        // Then
        #expect(controller.hasMismatch)
        #expect(!controller.isConfirmingPIN)
        #expect(savedPINs.isEmpty)
        #expect(await controller.submit("2468") == .confirmationRequired)
        #expect(!controller.hasMismatch)
        #expect(savedPINs.isEmpty)
        #expect(await controller.submit("2468") == .saved)
        #expect(savedPINs == ["2468"])
    }

    @Test func test_save_when_rejected_then_starts_a_fresh_attempt_without_success() async {
        // Given
        let controller = POSPINSetupController { _ in false }
        _ = await controller.submit("1234")

        // When
        let result = await controller.submit("1234")

        // Then
        #expect(result == .rejected)
        #expect(!controller.isSaving)
        #expect(!controller.isConfirmingPIN)
        #expect(await controller.submit("5678") == .confirmationRequired)
    }

    @Test func test_cancel_when_confirming_then_discards_input_without_saving() async {
        // Given
        var savedPINs: [String] = []
        let controller = POSPINSetupController { savedPINs.append($0); return true }
        _ = await controller.submit("1234")

        // When
        let cancelled = controller.cancel()

        // Then
        #expect(cancelled)
        #expect(!controller.isConfirmingPIN)
        #expect(!controller.hasMismatch)
        #expect(savedPINs.isEmpty)
        #expect(await controller.submit("5678") == .confirmationRequired)
    }

    @Test func test_submit_when_already_saving_then_rejects_reentry_and_cancel() async {
        // Given
        weak var savingController: POSPINSetupController?
        let controller = POSPINSetupController { _ in
            guard let savingController else { return false }
            #expect(savingController.isSaving)
            #expect(!savingController.cancel())
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
        let controller = POSPINSetupController { _ in true }
        _ = await controller.submit("1234")
        _ = await controller.submit("5678")

        // When
        controller.discardDraft()

        // Then
        #expect(!controller.hasMismatch)
        #expect(!controller.isConfirmingPIN)
        #expect(await controller.submit("2468") == .confirmationRequired)
    }
}
