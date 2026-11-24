import SwiftUI

struct POSPINEntryView: View {
    enum Style: Equatable {
        case approval
        case lockScreen(keySize: CGFloat)
        case setup(keySize: CGFloat, page: POSPINEntryPage, feedback: String?, feedbackMessages: [String])
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
    @State private var attemptPageID: Int?
    #if DEBUG
    private var previewEnteredPIN: String?
    #endif

    private let helper = POSPINEntryViewHelper()
    private let haptics = POSPINHapticFeedback()

    init(state: POSPINEntryState,
         pinLength: Int = 4,
         style: Style,
         onComplete: @escaping (String) async -> Bool) {
        self.state = state
        self.pinLength = pinLength
        self.style = style
        self.onComplete = onComplete
        self._attempt = State(initialValue: POSPINAttempt())
        self._attemptPageID = State(initialValue: Self.page(for: style)?.id)
    }

    var body: some View {
        content
        .onAppear {
            handleStateChange(state)
            #if DEBUG
            if let previewEnteredPIN { attempt = POSPINAttempt(pin: previewEnteredPIN) }
            #endif
        }
        .onChange(of: state) { oldState, newState in
            handleStateChange(newState)
            announceStateChange(from: oldState, to: newState)
        }
        .onChange(of: setupPage?.id) { _, pageID in
            attempt.startOver()
            attemptPageID = pageID
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

    var lockScreenKeySize: CGFloat? {
        switch style {
        case .approval:
            nil
        case .lockScreen(let keySize), .setup(let keySize, _, _, _):
            keySize
        }
    }

    var setupPage: POSPINEntryPage? {
        Self.page(for: style)
    }

    static func page(for style: Style) -> POSPINEntryPage? {
        guard case .setup(_, let page, _, _) = style else {
            return nil
        }
        return page
    }

    var setupFeedback: String? {
        guard case .setup(_, _, let feedback, _) = style, enteredPIN.isEmpty else {
            return nil
        }
        return feedback
    }

    /// A new setup page starts empty in the same update that slides it in.
    var enteredPIN: String {
        attemptPageID == setupPage?.id ? attempt.pin : ""
    }

    var setupFeedbackMessages: [String] {
        guard case .setup(_, _, _, let messages) = style else { return [] }
        return messages
    }

    var contentSpacing: CGFloat {
        switch style {
        case .approval:
            Self.contentSpacing
        case .lockScreen:
            metrics.spacing.xLarge
        case .setup:
            metrics.spacing.xxLarge + metrics.spacing.large
        }
    }

    var content: some View {
        VStack(spacing: contentSpacing) {
            statusRow
                .frame(maxWidth: .infinity, alignment: .center)
            numpad
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    var dotsRow: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<pinLength, id: \.self) { index in
                dot(filled: isLoading || index < enteredPIN.count)
            }
        }
        .modifier(ShakeEffect(animatableData: shakeAmount))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.dotsAccessibilityLabel)
        .accessibilityValue(Localization.dotsAccessibilityValue(entered: enteredPIN.count, total: pinLength))
        .frame(height: statusRowHeight)
    }

    func dot(filled: Bool) -> some View {
        Circle()
            .strokeBorder(Color.posOutline, lineWidth: lockScreenKeySize == nil ? Constants.dotBorderWidth : LockScreenConstants.dotBorderWidth)
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
            .transaction { transaction in
                if setupPage != nil && !filled && enteredPIN.isEmpty {
                    transaction.animation = nil
                }
            }
            .frame(width: dotSize, height: dotSize)
    }

    var dotSize: CGFloat {
        lockScreenKeySize == nil ? Constants.dotSize : LockScreenConstants.dotSize
    }

    var dotSpacing: CGFloat {
        lockScreenKeySize == nil ? metrics.spacing.medium : LockScreenConstants.dotSpacing
    }

    var statusRowHeight: CGFloat {
        lockScreenKeySize == nil ? Constants.statusRowHeight : LockScreenConstants.statusRowHeight
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

// MARK: - PIN feedback

private extension POSPINEntryView {
    var statusMessage: POSPINStatusMessage? {
        attempt.isMessageDeferred ? nil : helper.statusMessage(for: state, enteredPIN: attempt.pin)
    }

    var statusRow: some View {
        let message = statusMessage
        return ZStack {
            if style == .approval {
                // Measure every message up front so errors and countdown ticks cannot move the keys.
                ForEach(approvalFeedbackMessages, id: \.self) { text in
                    statusMessage(text).hidden()
                }
            }
            lockScreenDots
                .opacity(message == nil ? 1 : 0)
            if let message {
                Group {
                    if style == .approval {
                        statusMessage(approvalText(for: message))
                    } else {
                        lockScreenMessage(message)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(minHeight: lockScreenStatusMinHeight)
        .animation(style == .approval && reduceMotion ? nil : LockScreenConstants.feedbackAnimation, value: message == nil)
        // One stable element keeps VoiceOver focus in place while the dots and messages swap.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.dotsAccessibilityLabel)
        .accessibilityValue(setupFeedback ?? message.map(accessibilityText(for:)) ?? entryCountText)
        // The countdown changes every second; VoiceOver should read it on request rather than on each change.
        .accessibilityAddTraits(isWaiting ? .updatesFrequently : [])
    }

    var approvalFeedbackMessages: [String] {
        [Localization.invalidPINMessage, Localization.genericErrorMessage, Localization.unavailableMessage,
         helper.lockoutMessage(remainingSeconds: Constants.feedbackMeasurementWaitSeconds)]
    }

    func approvalText(for message: POSPINStatusMessage) -> String {
        switch message {
        case .lockout(let seconds): helper.lockoutMessage(remainingSeconds: seconds)
        default: accessibilityText(for: message)
        }
    }

    var isWaiting: Bool {
        if case .waiting = state {
            return true
        }
        return false
    }

    /// Reserve lock-screen feedback space; setup reserves its own error slot at accessibility sizes.
    var lockScreenStatusMinHeight: CGFloat {
        setupPage == nil && dynamicTypeSize.isAccessibilitySize ? lockScreenStatusLineHeight * 2 : LockScreenConstants.statusRowHeight
    }

    var entryCountText: String {
        Localization.dotsAccessibilityValue(entered: enteredPIN.count, total: pinLength)
    }

    func accessibilityText(for message: POSPINStatusMessage) -> String {
        switch message {
        case .error(let kind): Localization.message(for: kind)
        case .lockout(let remainingSeconds): helper.lockoutAccessibilityMessage(remainingSeconds: remainingSeconds)
        case .unavailable: Localization.unavailableMessage
        }
    }

    @ViewBuilder
    var lockScreenDots: some View {
        if let setupPage {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: metrics.spacing.small) {
                    setupPageDots(setupPage)
                    ZStack {
                        // Large-text errors need layout space without shifting the title or resizing the keypad.
                        ForEach(setupFeedbackMessages, id: \.self) { message in
                            setupFeedbackMessage(message).hidden()
                        }
                        if let setupFeedback {
                            setupFeedbackMessage(setupFeedback)
                        }
                    }
                }
            } else {
                setupPageDots(setupPage)
                    .offset(y: setupFeedback == nil ? 0 : -LockScreenConstants.feedbackRise)
                    .overlay(alignment: .top) {
                        if let setupFeedback {
                            setupFeedbackMessage(setupFeedback)
                                .offset(y: LockScreenConstants.statusRowHeight / 2 + LockScreenConstants.feedbackGap)
                                .transition(.offset(y: -LockScreenConstants.feedbackDrop).combined(with: .opacity))
                        }
                    }
                    .animation(reduceMotion ? nil : LockScreenConstants.setupFeedbackAnimation, value: setupFeedback)
            }
        } else {
            dotsRow
        }
    }

    func setupPageDots(_ page: POSPINEntryPage) -> some View {
        ZStack {
            dotsRow
                .id(page.id)
                .transition(pageTransition(edge: page.edge))
        }
        .frame(width: LockScreenConstants.pageTrackWidth)
        .clipped()
        .animation(LockScreenConstants.pageAnimation, value: page)
        .frame(maxWidth: .infinity)
    }

    func pageTransition(edge: HorizontalEdge) -> AnyTransition {
        guard !reduceMotion else {
            return .opacity
        }
        let distance = edge == .leading ? -LockScreenConstants.pageSlideDistance : LockScreenConstants.pageSlideDistance
        return .offset(x: distance).combined(with: .opacity)
    }

    func setupFeedbackMessage(_ text: String) -> some View {
        Text(text)
            .font(.posBodySmallRegular())
            .foregroundStyle(Color.posError)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
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
            text[range][AttributeScopes.SwiftUIAttributes.FontAttribute.self] = style
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
        let submittedGeneration = withAnimation(reduceMotion ? nil : LockScreenConstants.dotPopAnimation) {
            attempt.enter(digit, length: pinLength)
        }
        haptics.digitEntered()
        guard let submittedGeneration else {
            announceEntryCount()
            return
        }
        let pin = attempt.pin
        Task {
            let succeeded = await onComplete(pin)
            guard attempt.isCurrent(submittedGeneration) else { return }
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

    /// Speaks only the entered count while focus stays on the keypad, never the PIN itself.
    func announceEntryCount() {
        AccessibilityNotification.Announcement(entryCountText).post()
    }

    /// Announces from the new value: a task started by a key press still holds the state from before the check.
    func announceStateChange(from oldState: POSPINEntryState, to newState: POSPINEntryState) {
        let text: String
        switch helper.announcement(from: oldState, to: newState) {
        case .status(let message): text = accessibilityText(for: message)
        case .entryAvailable: text = Localization.entryAvailableMessage
        case nil: return
        }
        var announcement = AttributedString(text)
        // Later entry counts must not cut off an error or wait.
        announcement[AttributeScopes.AccessibilityAttributes.AnnouncementPriorityAttribute.self] = .high
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
        static let feedbackMeasurementWaitSeconds = 59 * 60 + 59
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
        static let pageAnimation: Animation = .easeOut(duration: 0.3)
        static let pageSlideDistance: CGFloat = 148
        // Four dots plus room for the shake.
        static let pageTrackWidth: CGFloat = 136
        static let setupFeedbackAnimation: Animation = .easeInOut(duration: 0.3)
        static let feedbackRise: CGFloat = 18
        static let feedbackDrop: CGFloat = 8
        static let feedbackGap: CGFloat = 4
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
        view._attempt = State(initialValue: POSPINAttempt(pin: enteredPIN))
        return view
    }
}

#Preview("Idle") {
    POSPINEntryView(state: .idle, style: .approval, onComplete: { _ in true })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Error") {
    POSPINEntryView(state: .error(kind: .invalidPIN), style: .approval, onComplete: { _ in false })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Waiting") {
    POSPINEntryView(state: .waiting(remainingSeconds: 30), style: .approval, onComplete: { _ in true })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Loading") {
    POSPINEntryView(state: .loading, style: .approval, onComplete: { _ in true })
        .posPadding(\.medium)
        .background(Color.posSurfaceContainerLow)
}

#Preview("Interactive (wrong PIN)") {
    @Previewable @State var state: POSPINEntryState = .idle
    POSPINEntryView(state: state, style: .approval, onComplete: { _ in
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
