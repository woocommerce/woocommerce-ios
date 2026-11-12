import Foundation

struct POSPINEntryViewHelper {
    func appending(_ digit: Character, to pin: String, length: Int) -> String {
        guard pin.count < length else {
            return pin
        }
        return pin + String(digit)
    }

    func removingLastDigit(from pin: String) -> String {
        String(pin.dropLast())
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
        case .lockout, .waiting, .unavailable, .loading:
            return false
        }
    }

    func remainingLockoutSeconds(until date: Date, now: Date = Date()) -> Int {
        max(0, Int(date.timeIntervalSince(now).rounded(.up)))
    }

    func lockoutMessage(remainingSeconds: Int) -> String {
        let seconds = max(0, remainingSeconds)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        let minutes = formatter.string(from: NSNumber(value: seconds / 60)) ?? String(seconds / 60)
        formatter.minimumIntegerDigits = 2
        let remainder = formatter.string(from: NSNumber(value: seconds % 60)) ?? String(format: "%02ld", seconds % 60)
        let duration = String.localizedStringWithFormat(Localization.durationFormat, minutes, remainder)
        return String.localizedStringWithFormat(Localization.lockoutFormat, duration)
    }
}

private extension POSPINEntryViewHelper {
    enum Localization {
        static let durationFormat = NSLocalizedString(
            "pos.pinEntry.lockout.minutesSecondsFormat",
            value: "%1$@:%2$@",
            comment: "Countdown duration. %1$@ is localized minutes; %2$@ is localized seconds padded to two digits, such as 0:30."
        )
        static let lockoutFormat = NSLocalizedString(
            "pos.pinEntry.lockout.incorrectAttemptsCountdown",
            value: "Too many incorrect attempts.\nTry again in %1$@.",
            comment: "Lock-out message on the POS PIN numpad. %1$@ is a localized minute-and-second duration such as 0:30 or 5:00."
        )
    }
}
