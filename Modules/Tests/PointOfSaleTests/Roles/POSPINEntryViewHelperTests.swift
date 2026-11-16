import Testing
import Foundation
@testable import PointOfSale

struct POSPINEntryViewHelperTests {
    private let helper = POSPINEntryViewHelper()

    @Test func test_appending_when_below_length_then_adds_digit() {
        // Given
        let pin = "12"

        // When
        let result = helper.appending("3", to: pin, length: 4)

        // Then
        #expect(result == "123")
    }

    @Test func test_appending_when_at_length_then_does_not_exceed() {
        // Given
        let pin = "1234"

        // When
        let result = helper.appending("5", to: pin, length: 4)

        // Then
        #expect(result == "1234")
    }

    @Test func test_removingLastDigit_when_pin_has_digits_then_drops_last() {
        // Given
        let pin = "123"

        // When
        let result = helper.removingLastDigit(from: pin)

        // Then
        #expect(result == "12")
    }

    @Test func test_removingLastDigit_when_empty_then_returns_empty() {
        // Given
        let pin = ""

        // When
        let result = helper.removingLastDigit(from: pin)

        // Then
        #expect(result.isEmpty)
    }

    @Test func test_isComplete_when_below_length_then_false() {
        // Given
        let pin = "12"

        // When
        let complete = helper.isComplete(pin, length: 4)

        // Then
        #expect(complete == false)
    }

    @Test func test_isComplete_when_at_length_then_true() {
        // Given
        let pin = "1234"

        // When
        let complete = helper.isComplete(pin, length: 4)

        // Then
        #expect(complete == true)
    }

    @Test func test_isComplete_when_above_length_then_false() {
        // Given
        let pin = "12345"

        // When
        let complete = helper.isComplete(pin, length: 4)

        // Then
        #expect(complete == false)
    }

    @Test func test_acceptingDigit_when_below_length_then_appends_without_submitting() {
        // Given
        let pin = "12"

        // When
        let result = helper.acceptingDigit("3", currentPIN: pin, length: 4)

        // Then
        #expect(result.pin == "123")
        #expect(result.shouldSubmit == false)
    }

    @Test func test_acceptingDigit_when_completing_then_submits() {
        // Given
        let pin = "123"

        // When
        let result = helper.acceptingDigit("4", currentPIN: pin, length: 4)

        // Then
        #expect(result.pin == "1234")
        #expect(result.shouldSubmit == true)
    }

    @Test func test_acceptingDigit_when_currentPIN_is_complete_then_starts_fresh_attempt() {
        // Given
        let pin = "1234"

        // When
        let result = helper.acceptingDigit("5", currentPIN: pin, length: 4)

        // Then
        #expect(result.pin == "5")
        #expect(result.shouldSubmit == false)
    }

    @Test func test_isInputEnabled_when_idle_or_error_then_true() {
        // Given / When / Then
        #expect(helper.isInputEnabled(for: .idle) == true)
        #expect(helper.isInputEnabled(for: .error(kind: .invalidPIN)) == true)
    }

    @Test func test_isInputEnabled_when_waiting_unavailable_checking_or_loading_then_false() {
        // Given / When / Then
        #expect(helper.isInputEnabled(for: .waiting(remainingSeconds: 30)) == false)
        #expect(helper.isInputEnabled(for: .unavailable) == false)
        #expect(helper.isInputEnabled(for: .checkingLockout) == false)
        #expect(helper.isInputEnabled(for: .loading) == false)
    }

    @Test func test_removingLastDigit_when_rejected_PIN_is_shaking_then_next_digit_starts_fresh_attempt() {
        // Given
        let rejectedPIN = "1234"

        // When
        let pinAfterDelete = helper.removingLastDigit(from: rejectedPIN, discardingSubmittedPIN: true)
        let nextInput = helper.acceptingDigit("5", currentPIN: pinAfterDelete, length: 4)

        // Then
        #expect(nextInput.pin == "5")
        #expect(nextInput.shouldSubmit == false)
    }

    @Test(arguments: [(-1, "0:00"), (0, "0:00"), (30, "0:30"), (300, "5:00"), (1800, "30:00"), (3600, "60:00")])
    func test_lockoutMessage_when_wait_changes_then_uses_minute_second_copy(seconds: Int, duration: String) {
        // Given / When
        let message = helper.lockoutMessage(remainingSeconds: seconds)

        // Then
        #expect(message == "Too many incorrect attempts.\nTry again in \(duration).")
    }

    @Test func test_showsDisabledKeys_when_waiting_or_unavailable_then_true() {
        // Given / When / Then
        #expect(helper.showsDisabledKeys(for: .waiting(remainingSeconds: 30)) == true)
        #expect(helper.showsDisabledKeys(for: .unavailable) == true)
    }

    @Test func test_showsDisabledKeys_when_entry_or_brief_check_then_false() {
        // Given / When / Then
        #expect(helper.showsDisabledKeys(for: .idle) == false)
        #expect(helper.showsDisabledKeys(for: .error(kind: .invalidPIN)) == false)
        #expect(helper.showsDisabledKeys(for: .checkingLockout) == false)
        #expect(helper.showsDisabledKeys(for: .loading) == false)
    }

    @Test func test_statusMessage_when_invalid_PIN_and_no_new_digit_then_shows_error() {
        // Given
        let state = POSPINEntryState.error(kind: .invalidPIN)

        // When
        let message = helper.statusMessage(for: state, enteredPIN: "")

        // Then
        #expect(message == .error(.invalidPIN))
    }

    @Test func test_statusMessage_when_new_digit_after_invalid_PIN_then_hides_error() {
        // Given
        let state = POSPINEntryState.error(kind: .invalidPIN)

        // When
        let message = helper.statusMessage(for: state, enteredPIN: "5")

        // Then
        #expect(message == nil)
    }

    @Test func test_statusMessage_when_waiting_then_shows_countdown_even_with_digits() {
        // Given
        let state = POSPINEntryState.waiting(remainingSeconds: 30)

        // When
        let message = helper.statusMessage(for: state, enteredPIN: "12")

        // Then
        #expect(message == .lockout(remainingSeconds: 30))
    }

    @Test func test_statusMessage_when_unavailable_then_shows_retrying_message() {
        // Given / When
        let message = helper.statusMessage(for: .unavailable, enteredPIN: "")

        // Then
        #expect(message == .unavailable)
    }

    @Test(arguments: [POSPINEntryState.idle, .checkingLockout, .loading])
    func test_statusMessage_when_entering_or_checking_then_shows_dots(state: POSPINEntryState) {
        // Given / When
        let message = helper.statusMessage(for: state, enteredPIN: "")

        // Then
        #expect(message == nil)
    }
}
