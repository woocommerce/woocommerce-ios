import StripeTerminal

extension CardReaderSoftwareUpdate {
    init(update: ReaderSoftwareUpdate) {
        self.estimatedUpdateTime = UpdateTimeEstimate(update.estimatedUpdateTime)
        self.deviceSoftwareVersion = update.deviceSoftwareVersion
    }
}
