import SwiftUI

struct POSRefundReasonView: View {
    @State private var reasonText: String
    @State private var buttonState: POSButtonState = .idle
    @State private var errorMessage: String?

    private let initialReason: String?
    private let onSave: (String) -> Void
    private let onClose: () -> Void

    init(initialReason: String?,
         onSave: @escaping (String) -> Void,
         onClose: @escaping () -> Void) {
        self._reasonText = State(initialValue: initialReason ?? "")
        self.initialReason = initialReason
        self.onSave = onSave
        self.onClose = onClose
    }

    private var isAddButtonEnabled: Bool {
        !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        POSSingleFieldInputView(
            title: Localization.title,
            placeholder: Localization.placeholder,
            buttonTitle: Localization.addButton,
            text: $reasonText,
            buttonState: $buttonState,
            errorMessage: $errorMessage,
            isButtonEnabled: isAddButtonEnabled,
            onSubmit: { saveReasonIfValid() },
            onClose: onClose
        )
    }
}

// MARK: - Private Methods

private extension POSRefundReasonView {
    func saveReasonIfValid() {
        let trimmedReason = reasonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else { return }
        onSave(trimmedReason)
    }
}

// MARK: - Localization

private extension POSRefundReasonView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundReasonView.title",
            value: "Refund reason",
            comment: "Title for the refund reason input screen"
        )

        static let placeholder = NSLocalizedString(
            "pos.refundReasonView.placeholder",
            value: "Reason for refunding order",
            comment: "Placeholder text for the refund reason text field"
        )

        static let addButton = NSLocalizedString(
            "pos.refundReasonView.addButton",
            value: "Add",
            comment: "Button to add the refund reason"
        )
    }
}

#if DEBUG
#Preview("POSRefundReasonView - Empty") {
    POSRefundReasonView(
        initialReason: nil,
        onSave: { _ in },
        onClose: {}
    )
}

#Preview("POSRefundReasonView - With Existing Reason") {
    POSRefundReasonView(
        initialReason: "Customer not happy with the order.",
        onSave: { _ in },
        onClose: {}
    )
}
#endif
