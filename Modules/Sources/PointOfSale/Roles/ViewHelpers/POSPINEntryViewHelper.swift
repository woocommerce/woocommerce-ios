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

    func isInputEnabled(for state: POSPINEntryState) -> Bool {
        switch state {
        case .idle, .error:
            return true
        case .lockout, .loading:
            return false
        }
    }

    func remainingLockoutSeconds(until date: Date, now: Date = Date()) -> Int {
        max(0, Int(date.timeIntervalSince(now).rounded(.up)))
    }

    func lockoutMessage(remainingSeconds: Int) -> String {
        String.localizedStringWithFormat(Localization.lockoutFormat, remainingSeconds)
    }
}

private extension POSPINEntryViewHelper {
    enum Localization {
        static let lockoutFormat = NSLocalizedString(
            "pos.pinEntry.lockout.countdown",
            value: "Too many attempts. Try again in %1$ds.",
            comment: "Lock-out message on the POS PIN numpad. %1$d is the seconds remaining; 's' abbreviates seconds (localize if needed)."
        )
    }
}
