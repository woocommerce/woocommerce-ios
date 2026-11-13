import Testing
@testable import PointOfSale

struct POSPaymentSuccessCelebrationTests {
    private let paymentSettings = MockPOSPaymentSettingsService()
    private let celebration = MockPaymentCaptureCelebration()

    @Test func celebrate_when_payment_success_sound_is_off_then_celebrates_without_sound() {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = false
        let sut = POSPaymentSuccessCelebration(paymentSettings: paymentSettings, celebration: celebration)

        // When
        sut.celebrate()

        // Then
        #expect(celebration.celebrationWasCalled)
        #expect(celebration.playedSound == false)
    }

    @Test func celebrate_when_payment_success_sound_is_on_then_celebrates_with_sound() {
        // Given
        paymentSettings.isPaymentSuccessSoundEnabled = true
        let sut = POSPaymentSuccessCelebration(paymentSettings: paymentSettings, celebration: celebration)

        // When
        sut.celebrate()

        // Then
        #expect(celebration.playedSound == true)
    }

    @Test func celebrate_when_setting_changes_after_creation_then_next_celebration_uses_new_value() {
        // Given
        let sut = POSPaymentSuccessCelebration(paymentSettings: paymentSettings, celebration: celebration)
        sut.celebrate()

        // When
        paymentSettings.isPaymentSuccessSoundEnabled = false
        sut.celebrate()

        // Then
        #expect(celebration.playedSound == false)
    }
}
