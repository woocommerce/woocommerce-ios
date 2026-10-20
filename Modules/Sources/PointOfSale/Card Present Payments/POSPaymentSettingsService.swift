import CocoaLumberjackSwift
import struct Storage.GeneralAppSettingsStorage

protocol POSPaymentSettingsServiceProtocol {
    var isPaymentSuccessSoundEnabled: Bool { get }
    func setPaymentSuccessSoundEnabled(_ isEnabled: Bool)
}

/// Payment settings set in POS Settings → Payments. They are kept per device, not per store, and survive app restarts.
struct POSPaymentSettingsService: POSPaymentSettingsServiceProtocol {
    private let generalAppSettings: GeneralAppSettingsStorage

    init(generalAppSettings: GeneralAppSettingsStorage = GeneralAppSettingsStorage()) {
        self.generalAppSettings = generalAppSettings
    }

    var isPaymentSuccessSoundEnabled: Bool {
        generalAppSettings.value(for: \.isPOSPaymentSuccessSoundEnabled)
    }

    func setPaymentSuccessSoundEnabled(_ isEnabled: Bool) {
        do {
            try generalAppSettings.setValue(isEnabled, for: \.isPOSPaymentSuccessSoundEnabled)
        } catch {
            DDLogError("⛔️ POSPaymentSettingsService: Failed to save the payment success sound setting: \(error)")
        }
    }
}
