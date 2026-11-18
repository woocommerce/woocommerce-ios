struct POSPINAttempt: Equatable {
    private(set) var pin: String
    private(set) var isMessageDeferred = false
    private(set) var generation = 0
    private let defersFailureMessage: Bool

    init(pin: String = "", defersFailureMessage: Bool) {
        self.pin = pin
        self.defersFailureMessage = defersFailureMessage
    }

    mutating func enter(_ digit: Character, length: Int) -> Int? {
        let result = POSPINEntryViewHelper().acceptingDigit(digit, currentPIN: pin, length: length)
        generation += 1
        pin = result.pin
        isMessageDeferred = defersFailureMessage && result.shouldSubmit
        return result.shouldSubmit ? generation : nil
    }

    mutating func delete() {
        pin = POSPINEntryViewHelper().removingLastDigit(from: pin, discardingSubmittedPIN: isMessageDeferred)
        generation += 1
        isMessageDeferred = false
    }

    func isCurrent(_ generation: Int) -> Bool {
        generation == self.generation
    }

    mutating func succeed(generation: Int) {
        guard isCurrent(generation) else { return }
        isMessageDeferred = false
    }

    mutating func revealFailure(generation: Int) {
        guard isCurrent(generation) else { return }
        pin = ""
        isMessageDeferred = false
    }

    mutating func clear() {
        pin = ""
    }
}
