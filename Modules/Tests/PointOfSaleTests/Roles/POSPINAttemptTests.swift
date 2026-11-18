import Testing
@testable import PointOfSale

struct POSPINAttemptTests {
    @Test func test_enter_when_digit_completes_PIN_then_returns_generation_and_defers_message() {
        // Given
        var sut = POSPINAttempt(pin: "123", defersFailureMessage: true)

        // When
        let generation = sut.enter("4", length: 4)

        // Then
        #expect(generation == sut.generation)
        #expect(sut.pin == "1234")
        #expect(sut.isMessageDeferred)
    }

    @Test func test_enter_when_message_is_not_deferred_then_never_defers() {
        // Given
        var sut = POSPINAttempt(pin: "123", defersFailureMessage: false)

        // When
        _ = sut.enter("4", length: 4)

        // Then
        #expect(sut.isMessageDeferred == false)
    }

    @Test func test_enter_when_digit_follows_rejected_PIN_during_shake_then_starts_new_PIN() {
        // Given
        var sut = POSPINAttempt(defersFailureMessage: true)
        let rejected = enterPIN("1234", into: &sut)

        // When
        _ = sut.enter("5", length: 4)
        sut.revealFailure(generation: rejected)

        // Then
        #expect(sut.pin == "5")
        #expect(sut.isMessageDeferred == false)
    }

    @Test func test_delete_when_rejected_PIN_is_shaking_then_discards_it() {
        // Given
        var sut = POSPINAttempt(defersFailureMessage: true)
        let rejected = enterPIN("1234", into: &sut)

        // When
        sut.delete()

        // Then
        #expect(sut.pin.isEmpty)
        #expect(sut.isMessageDeferred == false)

        // When
        let next = sut.enter("5", length: 4)
        sut.revealFailure(generation: rejected)

        // Then
        #expect(sut.pin == "5")
        #expect(next == nil)
    }

    @Test func test_reveal_failure_when_generation_is_current_then_clears_PIN_and_releases_message() {
        // Given
        var sut = POSPINAttempt(defersFailureMessage: true)
        let generation = enterPIN("1234", into: &sut)

        // When
        sut.revealFailure(generation: generation)

        // Then
        #expect(sut.pin.isEmpty)
        #expect(sut.isMessageDeferred == false)
    }

    @Test func test_succeed_when_generation_is_current_then_releases_message_deferral() {
        // Given
        var sut = POSPINAttempt(defersFailureMessage: true)
        let generation = enterPIN("1234", into: &sut)

        // When
        sut.succeed(generation: generation)

        // Then
        #expect(sut.pin == "1234")
        #expect(sut.isMessageDeferred == false)
    }

    @Test func test_succeed_when_generation_is_stale_then_keeps_newer_input() {
        // Given
        var sut = POSPINAttempt(defersFailureMessage: true)
        let older = enterPIN("1234", into: &sut)
        let newer = enterPIN("5678", into: &sut)

        // When
        sut.succeed(generation: older)

        // Then
        #expect(sut.isCurrent(older) == false)
        #expect(sut.isCurrent(newer))
        #expect(sut.pin == "5678")
        #expect(sut.isMessageDeferred)
    }
}

private extension POSPINAttemptTests {
    func enterPIN(_ pin: String, into attempt: inout POSPINAttempt) -> Int {
        var generation: Int?
        for digit in pin {
            generation = attempt.enter(digit, length: 4)
        }
        return generation ?? -1
    }
}
