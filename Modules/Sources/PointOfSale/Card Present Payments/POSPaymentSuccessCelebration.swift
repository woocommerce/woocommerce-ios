import protocol Yosemite.PaymentCaptureCelebrationProtocol
import class Yosemite.PaymentCaptureCelebration

/// Celebrates a successful POS payment, leaving out the sound when it is turned off in POS Settings → Payments.
/// The setting is read on every payment, so a change applies to the next payment without restarting POS.
public final class POSPaymentSuccessCelebration: PaymentCaptureCelebrationProtocol {
    private let paymentSettings: POSPaymentSettingsServiceProtocol
    private let celebration: PaymentCaptureCelebrationProtocol

    public convenience init() {
        self.init(paymentSettings: POSPaymentSettingsService(), celebration: PaymentCaptureCelebration())
    }

    init(paymentSettings: POSPaymentSettingsServiceProtocol, celebration: PaymentCaptureCelebrationProtocol) {
        self.paymentSettings = paymentSettings
        self.celebration = celebration
    }

    public func celebrate(playsSound: Bool) {
        celebration.celebrate(playsSound: playsSound && paymentSettings.isPaymentSuccessSoundEnabled)
    }
}
