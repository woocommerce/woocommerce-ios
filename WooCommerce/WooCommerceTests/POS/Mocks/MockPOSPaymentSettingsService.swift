@testable import PointOfSale

final class MockPOSPaymentSettingsService: POSPaymentSettingsServiceProtocol {
    var isPaymentSuccessSoundEnabled: Bool = true

    func setPaymentSuccessSoundEnabled(_ isEnabled: Bool) {
        isPaymentSuccessSoundEnabled = isEnabled
    }
}
