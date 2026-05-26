import SwiftUI

struct POSPINEntryView: View {
    private let state: POSPINEntryState
    private let pinLength: Int
    private let onComplete: (String) -> Void

    @State private var enteredPIN = ""
    @State private var shakeAmount: CGFloat = 0

    private let helper = POSPINEntryViewHelper()
    private let haptics = POSPINHapticFeedback()

    init(state: POSPINEntryState,
         pinLength: Int = 4,
         onComplete: @escaping (String) -> Void) {
        self.state = state
        self.pinLength = pinLength
        self.onComplete = onComplete
    }

    var body: some View {
        content
        .onAppear { handleStateChange(state) }
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
    }
}

// MARK: - Subviews

private extension POSPINEntryView {
    var isInputEnabled: Bool {
        helper.isInputEnabled(for: state)
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    var content: some View {
        VStack(spacing: Self.contentSpacing) {
            statusRow
                .frame(maxWidth: .infinity, alignment: .center)
            numpad
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var statusRow: some View {
        switch state {
        case .lockout(let until):
            lockoutCountdown(until: until)
        case .idle, .loading, .error:
            dotsRow
        }
    }

    var dotsRow: some View {
        TimelineView(.animation(paused: !isLoading)) { context in
            HStack(spacing: POSSpacing.medium) {
                ForEach(0..<pinLength, id: \.self) { index in
                    dot(filled: isLoading || index < enteredPIN.count,
                        yOffset: waveOffset(index: index, date: context.date))
                }
            }
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Localization.dotsAccessibilityLabel)
            .accessibilityValue(Localization.dotsAccessibilityValue(entered: enteredPIN.count, total: pinLength))
        }
        .frame(height: Constants.statusRowHeight)
    }

    func dot(filled: Bool, yOffset: CGFloat) -> some View {
        Circle()
            .fill(filled ? Color.posPrimary : Color.clear)
            .overlay(
                Circle().strokeBorder(filled ? Color.posPrimary : Color.posOutline,
                                      lineWidth: Constants.dotBorderWidth)
            )
            .frame(width: Constants.dotSize, height: Constants.dotSize)
            .offset(y: yOffset)
    }

    func waveOffset(index: Int, date: Date) -> CGFloat {
        guard isLoading else {
            return 0
        }
        let time = date.timeIntervalSinceReferenceDate
        return sin(time * Constants.waveSpeed + Double(index) * Constants.wavePhase) * Constants.waveHeight
    }

    func lockoutMessage(_ text: String) -> some View {
        Text(text)
            .font(.posBodyMediumRegular())
            .foregroundColor(.posError)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: Constants.statusRowHeight)
    }

    func lockoutCountdown(until date: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            lockoutMessage(helper.lockoutMessage(remainingSeconds: helper.remainingLockoutSeconds(until: date, now: context.date)))
        }
    }

    var numpad: some View {
        VStack(spacing: Constants.keySpacing) {
            ForEach(Constants.rows, id: \.self) { row in
                HStack(spacing: Constants.keySpacing) {
                    ForEach(row, id: \.self) { key in
                        keyButton(for: key)
                    }
                }
            }
        }
        .opacity(isInputEnabled ? 1 : Constants.disabledOpacity)
        .animation(.default, value: isInputEnabled)
    }

    @ViewBuilder
    func keyButton(for key: String) -> some View {
        switch key {
        case Constants.emptyKey:
            Color.clear.frame(width: Constants.keySize, height: Constants.keySize)
        case Constants.deleteKey:
            keyContainer(action: handleDelete) {
                Image(systemName: "delete.backward")
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
            }
            .accessibilityLabel(Localization.deleteAccessibilityLabel)
            .disabled(!isInputEnabled || enteredPIN.isEmpty)
        default:
            keyContainer(action: { handleDigit(key) }) {
                Text(key)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
            }
            .disabled(!isInputEnabled)
        }
    }

    func keyContainer<Label: View>(action: @escaping () -> Void, @ViewBuilder label: () -> Label) -> some View {
        Button(action: action) {
            label()
                .frame(width: Constants.keySize, height: Constants.keySize)
                .background(Color.posSurface)
                .cornerRadius(POSCornerRadiusStyle.medium.value)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input handling

private extension POSPINEntryView {
    func handleDigit(_ key: String) {
        guard isInputEnabled, let digit = key.first else {
            return
        }
        let result = helper.acceptingDigit(digit, currentPIN: enteredPIN, length: pinLength)
        enteredPIN = result.pin
        haptics.digitEntered()
        if result.shouldSubmit {
            onComplete(result.pin)
        }
    }

    func handleDelete() {
        guard isInputEnabled else {
            return
        }
        enteredPIN = helper.removingLastDigit(from: enteredPIN)
    }

    // Parent drives state per attempt (e.g. via .loading) so a repeated failure re-animates, and exits .lockout once the deadline passes.
    func handleStateChange(_ newState: POSPINEntryState) {
        switch newState {
        case .error(let kind):
            enteredPIN = ""
            haptics.attemptFailed()
            withAnimation(.linear(duration: Constants.shakeDuration)) {
                shakeAmount += 1
            }
            AccessibilityNotification.Announcement(Localization.message(for: kind)).post()
        case .idle:
            enteredPIN = ""
        case .loading, .lockout:
            break
        }
    }
}

// MARK: - Shake

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = Constants.shakeTravel * sin(animatableData * .pi * Constants.shakeCount)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }

    private enum Constants {
        static let shakeTravel: CGFloat = 8
        static let shakeCount: CGFloat = 3
    }
}

// MARK: - Constants

private extension POSPINEntryView {
    enum Constants {
        static let dotSize: CGFloat = 22
        static let statusRowHeight = dotSize
        static let dotBorderWidth: CGFloat = 2
        static let keySize: CGFloat = 72
        static let keySpacing: CGFloat = POSSpacing.medium
        static let keypadHeight = keySize * CGFloat(rows.count) + keySpacing * CGFloat(rows.count - 1)
        static let disabledOpacity: Double = 0.4
        static let shakeDuration: TimeInterval = 0.4
        static let waveHeight: CGFloat = 6
        static let waveSpeed: Double = 5.0
        static let wavePhase: Double = 0.7
        static let emptyKey = ""
        static let deleteKey = "delete"
        static let rows: [[String]] = [
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
        static let deleteAccessibilityLabel = NSLocalizedString(
            "pos.pinEntry.delete.accessibilityLabel",
            value: "Delete",
            comment: "Accessibility label for the delete key on the POS PIN numpad"
        )
        static let dotsAccessibilityLabel = NSLocalizedString(
            "pos.pinEntry.dots.accessibilityLabel",
            value: "PIN entry",
            comment: "Accessibility label for the PIN dots on the POS PIN numpad"
        )
        static let dotsAccessibilityValueFormat = NSLocalizedString(
            "pos.pinEntry.dots.accessibilityValue",
            value: "%1$d of %2$d digits entered",
            comment: "Accessibility value for the PIN dots. %1$d is the entered count, %2$d the total."
        )
        static func dotsAccessibilityValue(entered: Int, total: Int) -> String {
            String.localizedStringWithFormat(dotsAccessibilityValueFormat, entered, total)
        }
        static let invalidPINMessage = NSLocalizedString(
            "pos.pinEntry.error.invalidPIN",
            value: "Incorrect PIN. Try again.",
            comment: "VoiceOver announcement when an entered POS PIN is incorrect."
        )
        static let genericErrorMessage = NSLocalizedString(
            "pos.pinEntry.error.generic",
            value: "Something went wrong. Try again.",
            comment: "VoiceOver announcement when validating the entered POS PIN fails unexpectedly."
        )
        static func message(for kind: POSPINErrorKind) -> String {
            switch kind {
            case .invalidPIN: invalidPINMessage
            case .generic: genericErrorMessage
            }
        }
    }
}

extension POSPINEntryView {
    static let contentWidth: CGFloat = 420
    static let contentSpacing: CGFloat = POSSpacing.xLarge
    static let titleToPINSpacing: CGFloat = POSSpacing.large

    static var preferredHeight: CGFloat {
        Constants.statusRowHeight + contentSpacing + Constants.keypadHeight
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Idle") {
    POSPINEntryView(state: .idle, onComplete: { _ in })
        .padding()
        .background(Color.posSurfaceContainerLow)
}

#Preview("Error") {
    POSPINEntryView(state: .error(kind: .invalidPIN), onComplete: { _ in })
        .padding()
        .background(Color.posSurfaceContainerLow)
}

#Preview("Lockout") {
    POSPINEntryView(state: .lockout(until: Date().addingTimeInterval(30)), onComplete: { _ in })
        .padding()
        .background(Color.posSurfaceContainerLow)
}

#Preview("Loading") {
    POSPINEntryView(state: .loading, onComplete: { _ in })
        .padding()
        .background(Color.posSurfaceContainerLow)
}

#Preview("Interactive (wrong PIN)") {
    @Previewable @State var state: POSPINEntryState = .idle
    POSPINEntryView(state: state, onComplete: { _ in
        state = .loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            state = .error(kind: .invalidPIN)
        }
    })
    .padding()
    .background(Color.posSurfaceContainerLow)
}
#endif
