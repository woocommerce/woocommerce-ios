/// Tells whether this device has recorded a card payment for a store, from data already on the device.
public protocol POSCardPaymentHistoryProviding {
    @MainActor
    func hasRecordedCardPayment(siteID: Int64) async -> Bool
}
