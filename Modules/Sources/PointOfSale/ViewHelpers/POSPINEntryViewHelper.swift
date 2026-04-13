import SwiftUI

struct POSPINEntryViewHelper {
    enum MessageTone: Equatable {
        case error
        case muted

        var color: Color {
            switch self {
            case .error:
                return .posError
            case .muted:
                return .posOnSurfaceVariantLowest
            }
        }
    }

    struct InputUpdate: Equatable {
        let submittedPIN: String?
        let shouldResetState: Bool
    }

    let maxDigits: Int
    private(set) var enteredPIN: String

    init(maxDigits: Int, enteredPIN: String = "") {
        self.maxDigits = maxDigits
        self.enteredPIN = enteredPIN
    }

    func isDotFilled(at index: Int) -> Bool {
        index < enteredPIN.count
    }

    func displayMessage(for state: POSPINEntryState) -> String? {
        switch state {
        case .idle, .loading:
            return nil
        case .error(let message), .lockout(let message):
            return message
        }
    }

    func messageColor(for state: POSPINEntryState) -> Color {
        messageTone(for: state).color
    }

    func messageTone(for state: POSPINEntryState) -> MessageTone {
        switch state {
        case .lockout:
            return .muted
        case .error, .idle, .loading:
            return .error
        }
    }

    func isInputDisabled(for state: POSPINEntryState) -> Bool {
        switch state {
        case .lockout, .loading:
            return true
        case .idle, .error:
            return false
        }
    }

    mutating func handleDigit(_ digit: String, state: POSPINEntryState) -> InputUpdate {
        guard enteredPIN.count < maxDigits else {
            return InputUpdate(submittedPIN: nil, shouldResetState: false)
        }

        let shouldResetState = state != .idle
        enteredPIN += digit

        guard enteredPIN.count == maxDigits else {
            return InputUpdate(submittedPIN: nil, shouldResetState: shouldResetState)
        }

        return InputUpdate(submittedPIN: enteredPIN, shouldResetState: shouldResetState)
    }

    mutating func handleDelete(state: POSPINEntryState) -> Bool {
        guard enteredPIN.isNotEmpty else {
            return false
        }

        let shouldResetState = state != .idle
        enteredPIN.removeLast()
        return shouldResetState
    }

    mutating func applyStateChange(_ newState: POSPINEntryState) -> Bool {
        switch newState {
        case .loading:
            return false
        case .error:
            enteredPIN = ""
            return true
        case .lockout:
            enteredPIN = ""
            return false
        case .idle:
            return false
        }
    }
}
