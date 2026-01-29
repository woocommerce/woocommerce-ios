import SwiftUI

struct POSRefundReasonView: View {
    @Environment(\.posModalParentSize) private var parentSize
    @State private var reasonText: String
    @FocusState private var isTextFieldFocused: Bool

    private let initialReason: String?
    private let onSave: (String) -> Void
    private let onBack: () -> Void
    private let onClose: () -> Void

    init(initialReason: String?,
         onSave: @escaping (String) -> Void,
         onBack: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self._reasonText = State(initialValue: initialReason ?? "")
        self.initialReason = initialReason
        self.onSave = onSave
        self.onBack = onBack
        self.onClose = onClose
    }

    private var isAddButtonEnabled: Bool {
        !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView

            Spacer()

            textFieldView

            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            buttonSection
                .padding(.bottom, POSPadding.xLarge)
                .background(Color.posSurfaceBright)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurfaceBright)
        .posModalFullScreen()
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Subviews

private extension POSRefundReasonView {
    var headerView: some View {
        HStack(spacing: POSSpacing.medium) {
            Button {
                onBack()
            } label: {
                Text(Image(systemName: "chevron.backward"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.backButtonAccessibilityLabel)

            Text(Localization.title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)

            Spacer()

            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var textFieldView: some View {
        TextField("",
                  text: $reasonText,
                  prompt: Text(Localization.placeholder).foregroundColor(.posOnSurfaceVariantLowest))
            .foregroundStyle(Color.posOnSurface)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .multilineTextAlignment(.center)
            .font(POSFontStyle.posHeadingRegular)
            .focused($isTextFieldFocused)
            .onSubmit {
                saveReasonIfValid()
            }
            .padding(.horizontal, POSPadding.xLarge)
    }

    var buttonSection: some View {
        Button(action: {
            saveReasonIfValid()
        }, label: {
            Text(Localization.addButton)
        })
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .disabled(!isAddButtonEnabled)
        .padding(.horizontal, POSPadding.xLarge)
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
            comment: "This is the screen title displayed at the top of the refund reason input screen in the Point of Sale app, where merchants enter a reason for refunding a customer's order."
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReasonView.backButton.accessibilityLabel",
            value: "Back",
            comment: "This is an accessibility label for the back button on the refund reason input screen in the Point of Sale module. It helps screen readers and assistive technologies identify the navigation button that allows users to return to the previous screen when entering a refund reason."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReasonView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "This is the accessibility label for a close button on the refund reason input screen in a point-of-sale system. The button allows users to close/dismiss the refund reason view without completing the refund process."
        )

        static let placeholder = NSLocalizedString(
            "pos.refundReasonView.placeholder",
            value: "Reason for refunding order",
            comment: "This text appears as placeholder text in a text input field on the refund reason screen in a point-of-sale app, prompting users to enter why they are refunding an order."
        )

        static let addButton = NSLocalizedString(
            "pos.refundReasonView.addButton",
            value: "Add",
            comment: "Button label that appears on the Point of Sale refund reason screen, allowing users to add or save the refund reason they've entered in a text field."
        )
    }
}

#if DEBUG
#Preview("POSRefundReasonView - Empty") {
    POSRefundReasonView(
        initialReason: nil,
        onSave: { _ in },
        onBack: {},
        onClose: {}
    )
    .environmentObject(POSModalManager())
}

#Preview("POSRefundReasonView - With Existing Reason") {
    POSRefundReasonView(
        initialReason: "Customer not happy with the order.",
        onSave: { _ in },
        onBack: {},
        onClose: {}
    )
    .environmentObject(POSModalManager())
}
#endif
