import Testing
@testable import PointOfSale

struct POSPINEntryViewHelperTests {
    @Test func test_displayMessage_when_idle_then_returns_nil() {
        let sut = makeSUT()

        #expect(sut.displayMessage(for: .idle) == nil)
    }

    @Test func test_displayMessage_when_error_then_returns_error_message() {
        let sut = makeSUT()

        #expect(sut.displayMessage(for: .error(message: "Invalid PIN")) == "Invalid PIN")
    }

    @Test func test_displayMessage_when_lockout_then_returns_lockout_message() {
        let sut = makeSUT()

        #expect(sut.displayMessage(for: .lockout(message: "Try again later")) == "Try again later")
    }

    @Test func test_messageTone_when_error_then_returns_error_tone() {
        let sut = makeSUT()

        #expect(sut.messageTone(for: .error(message: "Invalid PIN")) == .error)
    }

    @Test func test_messageTone_when_lockout_then_returns_muted_tone() {
        let sut = makeSUT()

        #expect(sut.messageTone(for: .lockout(message: "Try again later")) == .muted)
    }

    @Test func test_isInputDisabled_when_lockout_then_returns_true() {
        let sut = makeSUT()

        #expect(sut.isInputDisabled(for: .lockout(message: "Try again later")) == true)
    }

    @Test func test_isInputDisabled_when_idle_then_returns_false() {
        let sut = makeSUT()

        #expect(sut.isInputDisabled(for: .idle) == false)
    }

    @Test func test_handleDigit_when_idle_and_not_complete_then_appends_digit() {
        var sut = makeSUT()

        let result = sut.handleDigit("1", state: .idle)

        #expect(sut.enteredPIN == "1")
        #expect(result == .init(submittedPIN: nil, shouldResetState: false))
    }

    @Test func test_handleDigit_when_reaching_max_digits_then_returns_submitted_pin() {
        var sut = makeSUT(enteredPIN: "123")

        let result = sut.handleDigit("4", state: .idle)

        #expect(sut.enteredPIN == "1234")
        #expect(result == .init(submittedPIN: "1234", shouldResetState: false))
    }

    @Test func test_handleDigit_when_non_idle_state_then_requests_state_reset() {
        var sut = makeSUT()

        let result = sut.handleDigit("1", state: .error(message: "Invalid PIN"))

        #expect(sut.enteredPIN == "1")
        #expect(result == .init(submittedPIN: nil, shouldResetState: true))
    }

    @Test func test_handleDigit_when_already_full_then_ignores_additional_digit() {
        var sut = makeSUT(enteredPIN: "1234")

        let result = sut.handleDigit("5", state: .idle)

        #expect(sut.enteredPIN == "1234")
        #expect(result == .init(submittedPIN: nil, shouldResetState: false))
    }

    @Test func test_handleDelete_when_pin_not_empty_then_removes_last_digit() {
        var sut = makeSUT(enteredPIN: "123")

        let shouldResetState = sut.handleDelete(state: .idle)

        #expect(sut.enteredPIN == "12")
        #expect(shouldResetState == false)
    }

    @Test func test_handleDelete_when_non_idle_state_then_requests_state_reset() {
        var sut = makeSUT(enteredPIN: "123")

        let shouldResetState = sut.handleDelete(state: .error(message: "Invalid PIN"))

        #expect(sut.enteredPIN == "12")
        #expect(shouldResetState == true)
    }

    @Test func test_handleDelete_when_pin_is_empty_then_does_nothing() {
        var sut = makeSUT()

        let shouldResetState = sut.handleDelete(state: .idle)

        #expect(sut.enteredPIN.isEmpty)
        #expect(shouldResetState == false)
    }

    @Test func test_applyStateChange_when_idle_then_clears_entered_pin_without_shake() {
        var sut = makeSUT(enteredPIN: "123")

        let shouldShake = sut.applyStateChange(.idle)

        #expect(sut.enteredPIN.isEmpty)
        #expect(shouldShake == false)
    }

    @Test func test_applyStateChange_when_error_then_clears_entered_pin_and_requests_shake() {
        var sut = makeSUT(enteredPIN: "123")

        let shouldShake = sut.applyStateChange(.error(message: "Invalid PIN"))

        #expect(sut.enteredPIN.isEmpty)
        #expect(shouldShake == true)
    }

    @Test func test_applyStateChange_when_lockout_then_clears_entered_pin_without_shake() {
        var sut = makeSUT(enteredPIN: "123")

        let shouldShake = sut.applyStateChange(.lockout(message: "Try again later"))

        #expect(sut.enteredPIN.isEmpty)
        #expect(shouldShake == false)
    }

    @Test func test_isDotFilled_when_index_is_less_than_entered_pin_count_then_returns_true() {
        let sut = makeSUT(enteredPIN: "12")

        #expect(sut.isDotFilled(at: 0) == true)
        #expect(sut.isDotFilled(at: 1) == true)
        #expect(sut.isDotFilled(at: 2) == false)
    }

    private func makeSUT(maxDigits: Int = 4, enteredPIN: String = "") -> POSPINEntryViewHelper {
        POSPINEntryViewHelper(maxDigits: maxDigits, enteredPIN: enteredPIN)
    }
}
