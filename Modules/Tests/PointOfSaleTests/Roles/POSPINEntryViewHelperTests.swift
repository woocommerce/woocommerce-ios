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
        #expect(helper.isInputEnabled(for: .error(message: "Incorrect PIN")) == true)
    }

    @Test func test_isInputEnabled_when_lockout_or_loading_then_false() {
        // Given / When / Then
        #expect(helper.isInputEnabled(for: .lockout(until: Date())) == false)
        #expect(helper.isInputEnabled(for: .loading) == false)
    }

    @Test func test_remainingLockoutSeconds_when_future_then_returns_positive() {
        // Given
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let until = now.addingTimeInterval(30)

        // When
        let seconds = helper.remainingLockoutSeconds(until: until, now: now)

        // Then
        #expect(seconds == 30)
    }

    @Test func test_remainingLockoutSeconds_when_past_then_clamps_to_zero() {
        // Given
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let until = now.addingTimeInterval(-5)

        // When
        let seconds = helper.remainingLockoutSeconds(until: until, now: now)

        // Then
        #expect(seconds == 0)
    }

    @Test func test_lockoutMessage_when_given_seconds_then_includes_count() {
        // Given
        let seconds = 30

        // When
        let message = helper.lockoutMessage(remainingSeconds: seconds)

        // Then
        #expect(message.contains("30"))
    }
}
