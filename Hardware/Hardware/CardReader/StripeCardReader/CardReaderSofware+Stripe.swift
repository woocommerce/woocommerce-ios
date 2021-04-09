import StripeTerminal

extension CardReaderSoftwareUpdate {

    /// Convenience initializer
    /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPReaderSoftwareUpdate.html
    /// - Parameter update: StripeTerminal.ReaderSoftwareUpdate
    init(update: ReaderSoftwareUpdate) {
        self.estimatedUpdateTime = UpdateTimeEstimate(update.estimatedUpdateTime)
        self.deviceSoftwareVersion = update.deviceSoftwareVersion
    }
}
