import SwiftUI
import Combine
import WooFoundation

/// A reusable single-field input view with a header, centered text field, and action button.
///
/// Used by views that follow the pattern: navigation header + centered text input + primary button.
/// Handles keyboard tracking, conditional padding, error display, and button state management.
///
/// Consumers provide domain-specific logic for validation, async actions, and analytics
struct POSSingleFieldInputView: View {
    let title: String
    let placeholder: String
    let buttonTitle: String
    @Binding var text: String
    @Binding var buttonState: POSButtonState
    @Binding var errorMessage: String?
    let isButtonEnabled: Bool
    let onSubmit: () -> Void
    let onClose: () -> Void

    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disableAutocorrection: Bool = false

    @FocusState private var isTextFieldFocused: Bool

    @State private var buttonFrame: CGRect = .zero
    @State private var keyboardFrame: CGRect = .zero
    @State private var shouldMinimizePadding: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                POSPageHeaderView(
                    title: title,
                    backButtonConfiguration: .init(
                        state: buttonState != .idle ? .disabled : .enabled,
                        action: {
                            withAnimation {
                                onClose()
                                isTextFieldFocused = false
                            }
                        }
                    )
                )

                VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                    Spacer()

                    VStack(alignment: .center, spacing: POSSpacing.xSmall) {
                        TextField("",
                                  text: $text,
                                  prompt: Text(placeholder).foregroundColor(.posOnDisabledContainer))
                        .foregroundStyle(Color.posOnSurface)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(disableAutocorrection)
                        .multilineTextAlignment(.center)
                        .font(POSFontStyle.posHeadingRegular)
                        .focused()
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            onSubmit()
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(POSFontStyle.posBodySmallRegular())
                                .foregroundColor(.posError)
                        }
                    }

                    Spacer()

                    Button(action: {
                        onSubmit()
                    }, label: {
                        Text(buttonTitle)
                    })
                    .measureFrame {
                        buttonFrame = $0
                    }
                    .buttonStyle(POSFilledButtonStyle(size: .normal, state: buttonState))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .frame(maxWidth: .infinity)
                    .disabled(buttonState != .idle || !isButtonEnabled)
                }
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, keyboardFrame.height)
            }
            .animation(.easeInOut, value: errorMessage)
            .onChange(of: text) {
                errorMessage = nil
            }
            .onReceive(Publishers.keyboardFrame) {
                keyboardFrame = $0
                shouldMinimizePadding = $0.intersects(buttonFrame)
            }
            .animation(.default, value: shouldMinimizePadding)
        }
        .background(Color.posSurfaceBright)
    }
}

// MARK: - Helpers

private extension POSSingleFieldInputView {
    enum Constants {
        static let minimumPadding: CGFloat = POSSpacing.xSmall
    }

    func conditionalPadding(_ padding: CGFloat) -> CGFloat {
        if shouldMinimizePadding {
            return Constants.minimumPadding
        }
        return padding
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Default") {
    POSSingleFieldInputView(
        title: "Email receipt",
        placeholder: "Type email",
        buttonTitle: "Send",
        text: .constant(""),
        buttonState: .constant(.idle),
        errorMessage: .constant(nil),
        isButtonEnabled: false,
        onSubmit: {},
        onClose: {},
        keyboardType: .emailAddress,
        autocapitalization: .never,
        disableAutocorrection: true
    )
}

#Preview("With Error") {
    POSSingleFieldInputView(
        title: "Add note",
        placeholder: "Type note",
        buttonTitle: "Add",
        text: .constant("Some text"),
        buttonState: .constant(.idle),
        errorMessage: .constant("Failed to save. Try again."),
        isButtonEnabled: true,
        onSubmit: {},
        onClose: {}
    )
}

#Preview("Loading") {
    POSSingleFieldInputView(
        title: "Refund reason",
        placeholder: "Reason for refunding order",
        buttonTitle: "Add",
        text: .constant("Customer request"),
        buttonState: .constant(.loading),
        errorMessage: .constant(nil),
        isButtonEnabled: true,
        onSubmit: {},
        onClose: {}
    )
}
#endif
