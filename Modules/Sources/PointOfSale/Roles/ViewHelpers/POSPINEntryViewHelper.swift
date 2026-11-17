import Foundation

struct POSPINEntryViewHelper {
    static let keypadRows = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "delete"]
    ]

    static func lockScreenKeySpacing(_ metrics: POSMetrics) -> CGFloat {
        metrics.spacing.small
    }

    static func lockScreenKeypadSize(keySize: CGFloat, metrics: POSMetrics) -> CGSize {
        let columns = CGFloat(keypadRows[0].count)
        let rows = CGFloat(keypadRows.count)
        let spacing = lockScreenKeySpacing(metrics)
        return CGSize(width: keySize * columns + spacing * (columns - 1),
                      height: keySize * rows + spacing * (rows - 1))
    }

    static func lockScreenKeySize(fitting size: CGSize, preferred: CGFloat, metrics: POSMetrics) -> CGFloat {
        let columns = CGFloat(keypadRows[0].count)
        let rows = CGFloat(keypadRows.count)
        let spacing = lockScreenKeySpacing(metrics)
        let widthLimit = (size.width - spacing * (columns - 1)) / columns
        let heightLimit = (size.height - spacing * (rows - 1)) / rows
        let minimum = max(Constants.minimumKeySize, preferred * Constants.minimumKeyScale)
        return min(preferred, max(minimum, min(widthLimit, heightLimit).rounded(.down)))
    }

    func appending(_ digit: Character, to pin: String, length: Int) -> String {
        guard pin.count < length else {
            return pin
        }
        return pin + String(digit)
    }

    func removingLastDigit(from pin: String, discardingSubmittedPIN: Bool = false) -> String {
        discardingSubmittedPIN ? "" : String(pin.dropLast())
    }

    func isComplete(_ pin: String, length: Int) -> Bool {
        pin.count == length
    }

    func acceptingDigit(_ digit: Character, currentPIN: String, length: Int) -> (pin: String, shouldSubmit: Bool) {
        let basePIN = isComplete(currentPIN, length: length) ? "" : currentPIN
        let newPIN = appending(digit, to: basePIN, length: length)
        return (newPIN, isComplete(newPIN, length: length))
    }

    func isInputEnabled(for state: POSPINEntryState) -> Bool {
        switch state {
        case .idle, .error:
            return true
        case .waiting, .unavailable, .checkingLockout, .loading:
            return false
        }
    }

    /// Keys that can't be used for a while look disabled. Brief checks keep their normal look so the keypad doesn't flicker.
    func showsDisabledKeys(for state: POSPINEntryState) -> Bool {
        switch state {
        case .waiting, .unavailable:
            return true
        case .idle, .error, .checkingLockout, .loading:
            return false
        }
    }

    func statusMessage(for state: POSPINEntryState, enteredPIN: String) -> POSPINStatusMessage? {
        switch state {
        case .waiting(let remainingSeconds):
            return .lockout(remainingSeconds: remainingSeconds)
        case .unavailable:
            return .unavailable
        case .error(let kind):
            return enteredPIN.isEmpty ? .error(kind) : nil
        case .idle, .checkingLockout, .loading:
            return nil
        }
    }

    func lockoutDuration(remainingSeconds: Int) -> String {
        Duration.seconds(max(0, remainingSeconds)).formatted(.time(pattern: .minuteSecond))
    }

    func lockoutMessage(remainingSeconds: Int) -> String {
        String.localizedStringWithFormat(Localization.lockoutFormat, lockoutDuration(remainingSeconds: remainingSeconds))
    }

    /// VoiceOver reads "0:30" as a time of day, so the spoken message uses unit names instead.
    func lockoutAccessibilityMessage(remainingSeconds: Int) -> String {
        let duration = Duration.seconds(max(0, remainingSeconds))
            .formatted(.units(allowed: [.minutes, .seconds], width: .wide))
        return String.localizedStringWithFormat(Localization.lockoutFormat, duration)
    }

    /// Announces each state boundary once. Countdown ticks stay silent; the status element reports the remaining wait on demand.
    func announcement(from oldState: POSPINEntryState, to newState: POSPINEntryState,
                      announcesWaits: Bool) -> POSPINAnnouncement? {
        switch (oldState, newState) {
        case (_, .error(let kind)) where oldState != newState:
            return .status(.error(kind))
        case (_, .unavailable) where oldState != .unavailable:
            return .status(.unavailable)
        case (.waiting, .waiting):
            return nil
        case (_, .waiting(let remainingSeconds)):
            return announcesWaits ? .status(.lockout(remainingSeconds: remainingSeconds)) : nil
        case (.waiting, .idle), (.unavailable, .idle):
            return announcesWaits ? .entryAvailable : nil
        default:
            return nil
        }
    }
}

enum POSPINStatusMessage: Equatable {
    case error(POSPINErrorKind)
    case lockout(remainingSeconds: Int)
    case unavailable
}

enum POSPINAnnouncement: Equatable {
    case status(POSPINStatusMessage)
    case entryAvailable
}

private extension POSPINEntryViewHelper {
    enum Constants {
        static let minimumKeySize: CGFloat = 60
        static let minimumKeyScale: CGFloat = 0.8
    }

    enum Localization {
        static let lockoutFormat = NSLocalizedString(
            "pos.pinEntry.lockout.incorrectAttemptsCountdown",
            value: "Too many incorrect attempts.\nTry again in %1$@.",
            comment: "Lock-out message on the POS PIN numpad. %1$@ is a localized duration, such as 0:30 on screen or 30 seconds for VoiceOver."
        )
    }
}
