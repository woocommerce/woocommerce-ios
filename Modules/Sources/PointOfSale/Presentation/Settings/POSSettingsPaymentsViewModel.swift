import Foundation
import Observation
import struct WooFoundation.WooAnalyticsEvent

@MainActor
@Observable
final class POSSettingsPaymentsViewModel {
    private(set) var isPaymentSuccessSoundEnabled: Bool

    @ObservationIgnored private let paymentSettings: POSPaymentSettingsServiceProtocol
    @ObservationIgnored private let analytics: POSAnalyticsProviding

    init(paymentSettings: POSPaymentSettingsServiceProtocol = POSPaymentSettingsService(),
         analytics: POSAnalyticsProviding) {
        self.paymentSettings = paymentSettings
        self.analytics = analytics
        self.isPaymentSuccessSoundEnabled = paymentSettings.isPaymentSuccessSoundEnabled
    }

    func setPaymentSuccessSoundEnabled(_ isEnabled: Bool) {
        guard isEnabled != isPaymentSuccessSoundEnabled else { return }
        paymentSettings.setPaymentSuccessSoundEnabled(isEnabled)
        isPaymentSuccessSoundEnabled = isEnabled
        analytics.track(event: .PointOfSale.paymentSuccessSoundToggled(isEnabled: isEnabled))
    }
}
