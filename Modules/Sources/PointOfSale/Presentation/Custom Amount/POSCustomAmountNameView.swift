import SwiftUI

struct POSCustomAmountNameView: View {
    @State private var name: String
    @State private var buttonState: POSButtonState = .idle
    @State private var errorMessage: String?
    let onBack: () -> Void
    let onSave: (String) -> Void

    init(name: String, onBack: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        self._name = State(initialValue: name)
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        POSSingleFieldInputView(title: Localization.title,
                                placeholder: AddCustomAmountView.Localization.namePlaceholder,
                                buttonTitle: POSCustomAmountAmountView.Localization.saveButton,
                                text: $name,
                                buttonState: $buttonState,
                                errorMessage: $errorMessage,
                                isButtonEnabled: true,
                                onSubmit: { onSave(name) },
                                onClose: onBack,
                                disableAutocorrection: true,
                                selectAllOnFocus: true,
                                submitLabel: .done,
                                textFieldAccessibilityIdentifier: "pos-custom-amount-name-field",
                                submitButtonAccessibilityIdentifier: "pos-custom-amount-name-save-button",
                                horizontalPadding: \.xLarge,
                                fillsAvailableHeight: true)
        .posEdgeSwipeBackAction(onBack: onBack)
    }
}

private extension POSCustomAmountNameView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.customAmount.nameStep.title", value: "Name",
            comment: "Title of the editor for the optional POS custom amount name.")
    }
}

#if DEBUG
#Preview {
    POSCustomAmountNameView(name: "Service fee", onBack: {}, onSave: { _ in })
}
#endif
