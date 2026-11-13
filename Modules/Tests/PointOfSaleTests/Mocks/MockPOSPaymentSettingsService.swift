@testable import PointOfSale

final class MockPOSPaymentSettingsService: POSPaymentSettingsServiceProtocol {
    var isPaymentSuccessSoundEnabled: Bool = true
    private(set) var setPaymentSuccessSoundEnabledValues: [Bool] = []

    func setPaymentSuccessSoundEnabled(_ isEnabled: Bool) {
        setPaymentSuccessSoundEnabledValues.append(isEnabled)
        isPaymentSuccessSoundEnabled = isEnabled
    }
}
