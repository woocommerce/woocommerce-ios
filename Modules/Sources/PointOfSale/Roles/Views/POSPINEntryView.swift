import SwiftUI

struct POSPINEntryView: View {
    enum Style: Equatable {
        case standard
        case lockScreen(keySize: CGFloat)
    }

    @Environment(\.posMetrics) private var metrics
    @Environment(\.posLayoutScale) private var layoutScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var lockScreenStatusLineHeight = LockScreenConstants.statusRowHeight
    private let state: POSPINEntryState
    private let pinLength: Int
    private let style: Style
    private let onComplete: (String) async -> Bool

    @State private var attempt: POSPINAttempt
    @State private var shakeAmount: CGFloat = 0
    #if DEBUG
    private var previewEnteredPIN: String?
    #endif

    private let helper = POSPINEntryViewHelper()
    private let haptics = POSPINHapticFeedback()

    init(state: POSPINEntryState,
         pinLength: Int = 4,
         style: Style = .standard,
         onComplete: @escaping (String) async -> Bool) {
        self.state = state
        self.pinLength = pinLength
        self.style = style
        self.onComplete = onComplete
        self._attempt = State(initialValue: POSPINAttempt(defersFailureMessage: style != .standard))
    }

    var body: some View {
        content
        .onAppear {
            handleStateChange(state)
            #if DEBUG
            if let previewEnteredPIN { attempt = POSPINAttempt(pin: previewEnteredPIN, defersFailureMessage: style != .standard) }
            #endif
        }
        .onChange(of: state) { oldState, newState in
            handleStateChange(newState)
            announceStateChange(from: oldState, to: newState)
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

    var animatesLoadingDots: Bool {
        isLoading && lockScreenKeySize == nil
    }

    var showsInvalidPINMessage: Bool {
        state == .error(kind: .invalidPIN) && attempt.pin.isEmpty
    }

    var lockScreenKeySize: CGFloat? {
        if case .lockScreen(let keySize) = style {
            return keySize
        }
        return nil
    }

    var content: some View {
        VStack(spacing: lockScreenKeySize == nil ? Self.contentSpacing : metrics.spacing.xLarge) {
            statusRow
                .frame(maxWidth: .infinity, alignment: .center)
            numpad
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var statusRow: some View {
        if lockScreenKeySize != nil {
            lockScreenStatusRow
        } else {
            standardStatusRow
        }
    }

    @ViewBuilder
    var standardStatusRow: some View {
        switch state {
        case .waiting(let seconds):
            statusMessage(helper.lockoutMessage(remainingSeconds: seconds))
        case .unavailable:
            statusMessage(Localization.unavailableMessage)
        case .error where showsInvalidPINMessage:
            statusMessage(Localization.message(for: .invalidPIN))
                .modifier(ShakeEffect(animatableData: shakeAmount))
        case .idle, .checkingLockout, .loading, .error:
            dotsRow
        }
    }

    var dotsRow: some View {
        TimelineView(.animation(paused: !animatesLoadingDots)) { context in
            HStack(spacing: dotSpacing) {
                ForEach(0..<pinLength, id: \.self) { index in
                    dot(filled: isLoading || index < attempt.pin.count,
                        yOffset: waveOffset(index: index, date: context.date))
                }
            }
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Localization.dotsAccessibilityLabel)
            .accessibilityValue(Localization.dotsAccessibilityValue(entered: attempt.pin.count, total: pinLength))
        }
        .frame(height: statusRowHeight)
    }

    @ViewBuilder
    func dot(filled: Bool, yOffset: CGFloat) -> some View {
        if lockScreenKeySize != nil {
            Circle()
                .strokeBorder(Color.posOutline, lineWidth: LockScreenConstants.dotBorderWidth)
                .overlay {
                    if filled {
                        Circle()
                            .fill(Color.posOnSurface)
                            .transition(reduceMotion ? .identity : .asymmetric(
                                insertion: .scale(scale: LockScreenConstants.dotPopScale).animation(LockScreenConstants.dotPopAnimation),
                                removal: .opacity
                            ))
                    }
                }
                .frame(width: LockScreenConstants.dotSize, height: LockScreenConstants.dotSize)
                .offset(y: yOffset)
        } else {
            Circle()
                .fill(filled ? Color.posPrimary : Color.clear)
                .overlay(
                    Circle().strokeBorder(filled ? Color.posPrimary : Color.posOutline,
                                          lineWidth: Constants.dotBorderWidth)
                )
                .frame(width: Constants.dotSize, height: Constants.dotSize)
                .offset(y: yOffset)
        }
    }

    var dotSpacing: CGFloat {
        lockScreenKeySize == nil ? metrics.spacing.medium : LockScreenConstants.dotSpacing
    }

    var statusRowHeight: CGFloat {
        lockScreenKeySize == nil ? Constants.statusRowHeight : LockScreenConstants.statusRowHeight
    }

    func waveOffset(index: Int, date: Date) -> CGFloat {
        guard animatesLoadingDots else {
            return 0
        }
        let time = date.timeIntervalSinceReferenceDate
        return sin(time * Constants.waveSpeed + Double(index) * Constants.wavePhase) * Constants.waveHeight
    }

    func statusMessage(_ text: String) -> some View {
        Text(text)
            .font(.posBodyMediumRegular())
            .foregroundColor(.posError)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: Constants.statusRowHeight)
    }

    var numpad: some View {
        VStack(spacing: keySpacing) {
            ForEach(POSPINEntryViewHelper.keypadRows, id: \.self) { row in
                HStack(spacing: keySpacing) {
                    ForEach(row, id: \.self) { key in
                        keyButton(for: key)
                    }
                }
            }
        }
        .opacity(lockScreenKeySize != nil || isInputEnabled ? 1 : Constants.disabledOpacity)
        .animation(.default, value: isInputEnabled)
    }

    var keySpacing: CGFloat {
        lockScreenKeySize == nil ? Constants.keySpacing : POSPINEntryViewHelper.lockScreenKeySpacing(metrics)
    }

    @ViewBuilder
    func keyButton(for key: String) -> some View {
        switch key {
        case Constants.emptyKey:
            let size = lockScreenKeySize ?? Constants.keySize
            Color.clear.frame(width: size, height: size)
        case Constants.deleteKey:
            keyContainer(action: handleDelete) {
                Label(Localization.deleteAccessibilityLabel,
                      systemImage: lockScreenKeySize == nil ? "delete.backward" : "delete.left")
                    .labelStyle(.iconOnly)
                    .font(.posHeadingBold)
            }
            .disabled(!isInputEnabled || attempt.pin.isEmpty)
        default:
            keyContainer(action: { handleDigit(key) }) {
                Text(key)
                    .font(.posHeadingBold)
            }
            .disabled(!isInputEnabled)
        }
    }

    @ViewBuilder
    func keyContainer<Label: View>(action: @escaping () -> Void, @ViewBuilder label: () -> Label) -> some View {
        if let lockScreenKeySize {
            Button(action: action, label: label)
                .buttonStyle(LockScreenKeyButtonStyle(size: lockScreenKeySize,
                                                      showsDisabledAppearance: helper.showsDisabledKeys(for: state)))
        } else {
            Button(action: action) {
                label()
                    .foregroundColor(.posOnSurface)
                    .frame(width: Constants.keySize, height: Constants.keySize)
                    .background(Color.posSurface)
                    .cornerRadius(POSCornerRadiusStyle.medium.value)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Lock screen status

private extension POSPINEntryView {
    var lockScreenStatusMessage: POSPINStatusMessage? {
        attempt.isMessageDeferred ? nil : helper.statusMessage(for: state, enteredPIN: attempt.pin)
    }

    var lockScreenStatusRow: some View {
        let message = lockScreenStatusMessage
        return ZStack {
            dotsRow
                .opacity(message == nil ? 1 : 0)
            if let message {
                lockScreenMessage(message)
                    .transition(.opacity)
            }
        }
        .frame(minHeight: lockScreenStatusMinHeight)
        .animation(LockScreenConstants.feedbackAnimation, value: message == nil)
        // One stable element keeps VoiceOver focus in place while the dots and messages swap.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.dotsAccessibilityLabel)
        .accessibilityValue(message.map(accessibilityText(for:)) ?? entryCountText)
        // The countdown changes every second; VoiceOver should read it on request rather than on each change.
        .accessibilityAddTraits(isWaiting ? .updatesFrequently : [])
    }

    var isWaiting: Bool {
        if case .waiting = state {
            return true
        }
        return false
    }

    /// Accessibility sizes wrap the error to two lines. Reserving them keeps the keys still when the next digit replaces it.
    var lockScreenStatusMinHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? lockScreenStatusLineHeight * 2 : LockScreenConstants.statusRowHeight
    }

    var entryCountText: String {
        Localization.dotsAccessibilityValue(entered: attempt.pin.count, total: pinLength)
    }

    func accessibilityText(for message: POSPINStatusMessage) -> String {
        switch message {
        case .error(let kind): Localization.message(for: kind)
        case .lockout(let remainingSeconds): helper.lockoutAccessibilityMessage(remainingSeconds: remainingSeconds)
        case .unavailable: Localization.unavailableMessage
        }
    }

    func lockScreenMessage(_ message: POSPINStatusMessage) -> some View {
        Group {
            switch message {
            case .error(let kind):
                Text(Localization.message(for: kind))
            case .lockout(let remainingSeconds):
                Text(lockoutText(remainingSeconds: remainingSeconds))
            case .unavailable:
                Text(Localization.unavailableMessage)
            }
        }
        .font(.posBodySmallRegular())
        .lineSpacing(LockScreenConstants.messageLineSpacing)
        .foregroundStyle(Color.posError)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    func lockoutText(remainingSeconds: Int) -> AttributedString {
        var text = AttributedString(helper.lockoutMessage(remainingSeconds: remainingSeconds))
        if let range = text.range(of: helper.lockoutDuration(remainingSeconds: remainingSeconds)) {
            let style = POSFontStyle.posBodySmallRegular()
            text[range].font = style
                .font(baseSize: style.baseSize(for: layoutScale), maximumContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
                .weight(.semibold)
        }
        return text
    }
}

// MARK: - Input handling

private extension POSPINEntryView {
    func handleDigit(_ key: String) {
        guard isInputEnabled, let digit = key.first else {
            return
        }
        let submittedGeneration: Int?
        if lockScreenKeySize != nil {
            submittedGeneration = withAnimation(reduceMotion ? nil : LockScreenConstants.dotPopAnimation) {
                attempt.enter(digit, length: pinLength)
            }
        } else {
            submittedGeneration = attempt.enter(digit, length: pinLength)
        }
        haptics.digitEntered()
        guard let submittedGeneration else {
            announceEntryCount()
            return
        }
        let pin = attempt.pin
        Task {
            let succeeded = await onComplete(pin)
            guard lockScreenKeySize == nil || attempt.isCurrent(submittedGeneration) else { return }
            if succeeded {
                attempt.succeed(generation: submittedGeneration)
            } else {
                handleFailedAttempt(generation: submittedGeneration)
            }
        }
    }

    func handleDelete() {
        guard isInputEnabled else {
            return
        }
        attempt.delete()
        announceEntryCount()
    }

    func handleStateChange(_ newState: POSPINEntryState) {
        if case .idle = newState {
            attempt.clear()
        }
    }

    func handleFailedAttempt(generation: Int) {
        haptics.attemptFailed()
        guard lockScreenKeySize != nil else {
            attempt.clear()
            withAnimation(.linear(duration: Constants.shakeDuration)) {
                shakeAmount += 1
            }
            return
        }
        guard !reduceMotion else {
            attempt.revealFailure(generation: generation)
            return
        }
        withAnimation(.linear(duration: Constants.shakeDuration)) {
            shakeAmount += 1
        } completion: {
            attempt.revealFailure(generation: generation)
        }
    }

    /// The lock screen's focus stays on the keypad, so the entered count is spoken there. The PIN itself never is.
    func announceEntryCount() {
        guard lockScreenKeySize != nil else { return }
        AccessibilityNotification.Announcement(entryCountText).post()
    }

    /// Announces from the new value: a task started by a key press still holds the state from before the check.
    func announceStateChange(from oldState: POSPINEntryState, to newState: POSPINEntryState) {
        let text: String
        switch helper.announcement(from: oldState, to: newState, announcesWaits: lockScreenKeySize != nil) {
        case .status(let message): text = accessibilityText(for: message)
        case .entryAvailable: text = Localization.entryAvailableMessage
        case nil: return
        }
        var announcement = AttributedString(text)
        // Later entry counts must not cut off an error or wait.
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }
}

// MARK: - Lock screen keys

private struct LockScreenKeyButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    let size: CGFloat
    let showsDisabledAppearance: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(showsDisabledAppearance ? Color.posOnDisabledContainer : Color.posOnSurface)
            .frame(width: size, height: size)
            .background(background(isPressed: configuration.isPressed),
                        in: RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value))
            .contentShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.large.value))
            // Larger digits would not fit the fixed-size keys.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func background(isPressed: Bool) -> Color {
        if showsDisabledAppearance {
            // The dark disabled container is lighter than enabled keys, so dark mode dims only the digits, as in the design.
            return colorScheme == .dark ? .posSurfaceDim : .posDisabledContainer
        }
        return isPressed ? .posSurfaceContainerLowest : .posSurfaceDim
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
        static let keySpacing: CGFloat = POSMetrics.Scale.regular.medium
        static let keypadHeight = keySize * CGFloat(POSPINEntryViewHelper.keypadRows.count)
            + keySpacing * CGFloat(POSPINEntryViewHelper.keypadRows.count - 1)
        static let disabledOpacity: Double = 0.4
        static let shakeDuration: TimeInterval = 0.4
        static let waveHeight: CGFloat = 6
        static let waveSpeed: Double = 5.0
        static let wavePhase: Double = 0.7
        static let emptyKey = ""
        static let deleteKey = "delete"
    }

    enum LockScreenConstants {
        static let dotSize: CGFloat = 20
        static let dotSpacing = POSMetrics.Scale.compact.medium
        static let dotBorderWidth: CGFloat = 1
        static let dotPopScale: CGFloat = 1.2
        static let statusRowHeight: CGFloat = 24
        // Brings Body Small to the design's 24pt line height for the two-line lockout message.
        static let messageLineSpacing = POSMetrics.Scale.regular.xSmall
        static let dotPopAnimation: Animation = .spring(duration: 0.2)
        static let feedbackAnimation: Animation = .easeOut(duration: 0.12)
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
            comment: "Error message and VoiceOver announcement when an entered POS PIN is incorrect."
        )
        static let genericErrorMessage = NSLocalizedString(
            "pos.pinEntry.error.generic",
            value: "Something went wrong. Try again.",
            comment: "Error message and VoiceOver announcement when validating the entered POS PIN fails unexpectedly."
        )
        static let entryAvailableMessage = NSLocalizedString(
            "pos.pinEntry.entryAvailable.accessibilityAnnouncement",
            value: "You can enter your PIN now.",
            comment: "VoiceOver announcement on the POS lock screen when a wait or temporary problem ends and the keypad is enabled again."
        )
        static let unavailableMessage = NSLocalizedString(
            "pos.pinEntry.unavailable.retrying",
            value: "Something went wrong. Retrying…",
            comment: "Message and VoiceOver announcement when the POS PIN check is unavailable. The app retries automatically while input is disabled."
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
    static let contentSpacing: CGFloat = POSMetrics.Scale.regular.xLarge

    static var lockScreenStatusRowHeight: CGFloat { LockScreenConstants.statusRowHeight }

    static var preferredHeight: CGFloat {
        Constants.statusRowHeight + contentSpacing + Constants.keypadHeight
    }
}

// MARK: - Preview

#if DEBUG
extension POSPINEntryView {
    func previewing(enteredPIN: String) -> Self {
        var view = self
        view.previewEnteredPIN = enteredPIN
        view._attempt = State(initialValue: POSPINAttempt(pin: enteredPIN, defersFailureMessage: style != .standard))
        return view
    }
}

#Preview("Idle") {
    POSPINEntryView(state: .idle, onComplete: { _ in true })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Error") {
    POSPINEntryView(state: .error(kind: .invalidPIN), onComplete: { _ in false })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Waiting") {
    POSPINEntryView(state: .waiting(remainingSeconds: 30), onComplete: { _ in true })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Loading") {
    POSPINEntryView(state: .loading, onComplete: { _ in true })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Interactive (wrong PIN)") {
    @Previewable @State var state: POSPINEntryState = .idle
    POSPINEntryView(state: state, onComplete: { _ in
        state = .loading
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                state = .error(kind: .invalidPIN)
                continuation.resume(returning: false)
            }
        }
    })
    .posPadding(\.medium)
    .background(Color.posSurfaceContainerLow)
}
#endif
