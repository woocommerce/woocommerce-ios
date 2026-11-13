import Testing
@testable import PointOfSale

@MainActor
struct POSSettingsPaymentsViewModelTests {
    private let paymentSettings = MockPOSPaymentSettingsService()
    private let analytics = MockPOSAnalytics()

    @Test(arguments: [true, false])
    func init_when_setting_is_stored_then_loads_current_value(isEnabled: Bool) {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = isEnabled

        // When
        let sut = POSSettingsPaymentsViewModel(paymentSettings: paymentSettings, analytics: analytics)

        // Then
        #expect(sut.isPaymentSuccessSoundEnabled == isEnabled)
    }

    @Test(arguments: [true, false])
    func setPaymentSuccessSoundEnabled_when_value_changes_then_saves_it_and_tracks_new_value(isEnabled: Bool) throws {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = !isEnabled
        let sut = POSSettingsPaymentsViewModel(paymentSettings: paymentSettings, analytics: analytics)

        // When
        sut.setPaymentSuccessSoundEnabled(isEnabled)

        // Then
        #expect(sut.isPaymentSuccessSoundEnabled == isEnabled)
        #expect(paymentSettings.setPaymentSuccessSoundEnabledValues == [isEnabled])
        let event = try #require(analytics.events.first)
        #expect(analytics.events.count == 1)
        #expect(event.eventName == "payment_success_sound_toggled")
        #expect(event.properties["enabled"] as? String == (isEnabled ? "true" : "false"))
    }

    @Test func setPaymentSuccessSoundEnabled_when_value_is_unchanged_then_does_not_save_or_track() {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = true
        let sut = POSSettingsPaymentsViewModel(paymentSettings: paymentSettings, analytics: analytics)

        // When
        sut.setPaymentSuccessSoundEnabled(true)

        // Then
        #expect(paymentSettings.setPaymentSuccessSoundEnabledValues.isEmpty)
        #expect(analytics.events.isEmpty)
    }
}
