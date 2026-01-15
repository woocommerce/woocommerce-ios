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
            comment: "Title for the refund reason input screen"
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReasonView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for back button on refund reason screen"
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReasonView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund reason screen"
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
