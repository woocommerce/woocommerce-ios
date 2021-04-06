import StripeTerminal

extension CardReaderEvent {
    /// Convenience initializer
    /// - Parameter readerInputOptions: An instance of a StripeTerminal.ReaderInputOptions
    init(readerInputOptions: ReaderInputOptions) {
        self.type = .waitingForInput
        self.message = Terminal.stringFromReaderInputOptions(readerInputOptions)
    }

    /// Convenience initializer
    /// - Parameter readerInputOptions: An instance of a StripeTerminal.ReaderDisplayMessage
    init(displayMessage: ReaderDisplayMessage) {
        self.type = .displayMessage
        self.message = Terminal.stringFromReaderDisplayMessage(displayMessage)
    }
}
