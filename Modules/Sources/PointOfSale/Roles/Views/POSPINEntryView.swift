import SwiftUI

/// External state that the parent can set to control the PIN entry view.
enum POSPINEntryState: Equatable {
    /// Normal input state.
    case idle
    /// Shows an error message and triggers a shake animation, then resets the entered digits.
    case error(message: String)
    /// Disables the numpad and shows a lockout countdown message.
    case lockout(message: String)
    /// Disables the numpad and shows a pulse animation on the PIN dots during remote verification.
    case loading
}

/// Reusable PIN numpad component for lock screen, manager override, and exit POS.
/// Supports 4-6 digit PINs with auto-submit, error shake animation, and lockout state.
struct POSPINEntryView: View {
    let title: String
    let subtitle: String?
    let maxDigits: Int
    let onPINEntered: (String) -> Void
    let onCancel: (() -> Void)?

    @Binding var state: POSPINEntryState

    @State private var helper: POSPINEntryViewHelper
    @State private var shakeOffset: CGFloat = 0

    init(title: String,
         subtitle: String? = nil,
         maxDigits: Int = 4,
         state: Binding<POSPINEntryState>,
         onPINEntered: @escaping (String) -> Void,
         onCancel: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.maxDigits = maxDigits
        self._state = state
        self.onPINEntered = onPINEntered
        self.onCancel = onCancel
        self._helper = State(initialValue: POSPINEntryViewHelper(maxDigits: maxDigits))
    }

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            headerSection
            pinDotsRow
            numpad
            if let onCancel {
                cancelButton(action: onCancel)
            }
        }
        .frame(maxWidth: Constants.maxWidth)
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: POSSpacing.small) {
            Text(title)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(2)

            if let subtitle {
                Text(subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - PIN Dots

    private var isLoading: Bool {
        state == .loading
    }

    private var pinDotsRow: some View {
        VStack(spacing: POSSpacing.medium) {
            HStack(spacing: POSSpacing.medium) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    pinDot(filled: helper.isDotFilled(at: index))
                }
            }
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isLoading)
            .offset(x: shakeOffset)

            Group {
                if let displayMessage {
                    Text(displayMessage)
                        .font(.posBodyMediumRegular())
                        .foregroundColor(messageColor)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .frame(height: Constants.errorMessageHeight)
        }
        .animation(.default, value: displayMessage)
    }

    private var displayMessage: String? {
        helper.displayMessage(for: state)
    }

    private var messageColor: Color {
        helper.messageColor(for: state)
    }

    private var isInputDisabled: Bool {
        helper.isInputDisabled(for: state)
    }

    private func pinDot(filled: Bool) -> some View {
        Circle()
            .fill(filled ? Color.posPrimary : Color.clear)
            .overlay(
                Circle()
                    .strokeBorder(filled ? Color.posPrimary : Color.posOutline,
                                  lineWidth: Constants.dotBorderWidth)
            )
            .frame(width: Constants.dotSize, height: Constants.dotSize)
    }

    // MARK: - Numpad

    private var numpad: some View {
        VStack(spacing: POSSpacing.medium) {
            ForEach(Constants.numpadRows, id: \.self) { row in
                HStack(spacing: POSSpacing.medium) {
                    ForEach(row, id: \.self) { key in
                        numpadButton(for: key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func numpadButton(for key: String) -> some View {
        if key == Constants.emptyKey {
            Color.clear
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
        } else if key == Constants.deleteKey {
            Button {
                handleDelete()
            } label: {
                Image(systemName: "delete.backward")
                    .font(.posBodyXLargeRegular)
                    .foregroundColor(.posOnSurface)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
            }
            .disabled(isInputDisabled || helper.enteredPIN.isEmpty)
            .accessibilityLabel(Localization.deleteAccessibilityLabel)
        } else {
            Button {
                handleDigit(key)
            } label: {
                Text(key)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    .background(Color.posSurfaceContainerLow)
                    .cornerRadius(POSCornerRadiusStyle.medium.value)
            }
            .disabled(isInputDisabled)
        }
    }

    // MARK: - Cancel Button

    private func cancelButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(Localization.cancel)
        }
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }

    // MARK: - Input Handling

    private func handleDigit(_ digit: String) {
        let update = helper.handleDigit(digit, state: state)
        if update.shouldResetState {
            state = .idle
        }
        if let pin = update.submittedPIN {
            onPINEntered(pin)
        }
    }

    private func handleDelete() {
        if helper.handleDelete(state: state) {
            state = .idle
        }
    }

    // MARK: - State Change Handling

    private func handleStateChange(_ newState: POSPINEntryState) {
        if helper.applyStateChange(newState) {
            triggerShake()
        }
    }

    private func triggerShake() {
        withAnimation(.default) {
            shakeOffset = Constants.shakeDistance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.shakeStepDuration) {
            withAnimation(.default) {
                shakeOffset = -Constants.shakeDistance
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.shakeStepDuration * 2) {
            withAnimation(.default) {
                shakeOffset = Constants.shakeDistance / 2
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.shakeStepDuration * 3) {
            withAnimation(.default) {
                shakeOffset = 0
            }
        }
    }
}

// MARK: - Constants

private extension POSPINEntryView {
    enum Constants {
        static let maxWidth: CGFloat = 400
        static let buttonSize: CGFloat = 72
        static let dotSize: CGFloat = 16
        static let dotBorderWidth: CGFloat = 2
        static let errorMessageHeight: CGFloat = 20
        static let shakeDistance: CGFloat = 10
        static let shakeStepDuration: TimeInterval = 0.08
        static let emptyKey = ""
        static let deleteKey = "DEL"
        static let numpadRows: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [emptyKey, "0", deleteKey]
        ]
    }
}

// MARK: - Localization

private extension POSPINEntryView {
    enum Localization {
        static let cancel = NSLocalizedString(
            "pos.pinEntry.cancel",
            value: "Cancel",
            comment: "Cancel button on the POS PIN entry numpad"
        )
        static let deleteAccessibilityLabel = NSLocalizedString(
            "pos.pinEntry.delete.accessibilityLabel",
            value: "Delete",
            comment: "Accessibility label for the delete button on the POS PIN entry numpad"
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("PIN Entry - Default") {
    @Previewable @State var pinState: POSPINEntryState = .idle

    POSPINEntryView(
        title: "Enter your PIN",
        subtitle: "Enter your 4-digit PIN to continue",
        state: $pinState,
        onPINEntered: { pin in
            pinState = .error(message: "Invalid PIN")
        },
        onCancel: {}
    )
    .padding()
    .background(Color.posSurfaceDim)
}

#Preview("PIN Entry - Lockout") {
    @Previewable @State var pinState: POSPINEntryState = .lockout(message: "Too many attempts. Try again in 30s.")

    POSPINEntryView(
        title: "Enter your PIN",
        state: $pinState,
        onPINEntered: { _ in }
    )
    .padding()
    .background(Color.posSurfaceDim)
}
#endif
