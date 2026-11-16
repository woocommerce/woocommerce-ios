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
        case .waiting, .unavailable, .checkingLockout, .loading:
            return false
        }
    }

    func lockoutMessage(remainingSeconds: Int) -> String {
        let duration = Duration.seconds(max(0, remainingSeconds)).formatted(.time(pattern: .minuteSecond))
        return String.localizedStringWithFormat(Localization.lockoutFormat, duration)
    }
}

private extension POSPINEntryViewHelper {
    enum Localization {
        static let lockoutFormat = NSLocalizedString(
            "pos.pinEntry.lockout.incorrectAttemptsCountdown",
            value: "Too many incorrect attempts.\nTry again in %1$@.",
            comment: "Lock-out message on the POS PIN numpad. %1$@ is a localized minute-and-second duration such as 0:30 or 5:00."
        )
    }
}
