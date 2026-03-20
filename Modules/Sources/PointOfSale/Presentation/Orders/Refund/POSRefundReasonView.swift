import SwiftUI

struct POSRefundReasonView: View {
    @Environment(\.posModalParentSize) private var parentSize
    @State private var reasonText: String
    @FocusState private var isTextFieldFocused: Bool

    private let initialReason: String?
    private let onSave: (String) -> Void
    private let onBack: () -> Void

    init(initialReason: String?,
         onSave: @escaping (String) -> Void,
         onBack: @escaping () -> Void) {
        self._reasonText = State(initialValue: initialReason ?? "")
        self.initialReason = initialReason
        self.onSave = onSave
        self.onBack = onBack
    }

    private var isAddButtonEnabled: Bool {
        !reasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: POSSpacing.medium) {
                POSPageHeaderView(
                    title: Localization.title,
                    backButtonConfiguration: .init(
                        state: .enabled,
                        action: onBack
                    )
                )

                VStack(alignment: .center, spacing: POSSpacing.medium) {
                    Spacer()

                    textFieldView

                    Spacer()

                    buttonSection
                }
                .padding([.horizontal])
            }
        }
        .background(Color.posSurfaceBright)
        .posModalFullScreen()
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Subviews

private extension POSRefundReasonView {
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
        onBack: {}
    )
    .environmentObject(POSModalManager())
}

#Preview("POSRefundReasonView - With Existing Reason") {
    POSRefundReasonView(
        initialReason: "Customer not happy with the order.",
        onSave: { _ in },
        onBack: {}
    )
    .environmentObject(POSModalManager())
}
#endif
