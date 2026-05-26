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
        case .lockout, .loading:
            return false
        }
    }

    func remainingLockoutSeconds(until date: Date, now: Date = Date()) -> Int {
        max(0, Int(date.timeIntervalSince(now).rounded(.up)))
    }

    func lockoutMessage(remainingSeconds: Int) -> String {
        let duration = Self.durationFormatter.string(from: TimeInterval(max(0, remainingSeconds))) ?? ""
        return String.localizedStringWithFormat(Localization.lockoutFormat, duration)
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()
}

private extension POSPINEntryViewHelper {
    enum Localization {
        static let lockoutFormat = NSLocalizedString(
            "pos.pinEntry.lockout.countdown",
            value: "Too many attempts. Try again in %1$@.",
            comment: "Lock-out message on the POS PIN numpad. %1$@ is a localized duration such as 30s or 1m 30s."
        )
    }
}
