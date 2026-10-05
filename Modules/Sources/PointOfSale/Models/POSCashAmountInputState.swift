struct POSCashAmountInputState: Equatable {
    var amount: String = ""
    var displayText: String = ""
    var inputDigits: String = ""
    var hasAppliedPreset: Bool = false
    var isDisplayingPreset: Bool = false
    var isSubmitting: Bool = false
    var errorMessage: String?
}
