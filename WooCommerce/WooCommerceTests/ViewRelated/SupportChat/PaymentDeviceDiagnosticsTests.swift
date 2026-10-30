import Foundation
import Testing
import Yosemite
import enum WooFoundation.BluetoothAuthorization
import protocol WooFoundation.BluetoothAuthorizationProviding
@testable import Hardware
@testable import WooCommerce

@MainActor
struct PaymentDeviceDiagnosticsTests {
    @Test func test_run_when_bluetooth_allowed_and_tap_to_pay_supported_then_passes_without_notes() async {
        // Given
        let sut = makeSUT(bluetooth: .allowed, tapToPaySupported: true)

        // When
        let result = await sut.run()

        // Then
        #expect(result.isSuccess)
        #expect(result.advisoryMessage == nil)
        #expect(result.technicalDetails?.contains("bluetooth=allowed; tap_to_pay=supported; connected_reader=none") == true)
    }

    @Test func test_run_when_bluetooth_denied_and_tap_to_pay_supported_then_passes_with_bluetooth_note() async {
        // Given
        let sut = makeSUT(bluetooth: .denied, tapToPaySupported: true)

        // When
        let result = await sut.run()

        // Then
        #expect(result.isSuccess)
        #expect(result.advisoryMessage == PaymentDeviceDiagnostics.Localization.bluetoothDenied)
    }

    @Test(arguments: [true, false])
    func test_run_when_bluetooth_denied_and_tap_to_pay_unavailable_then_fails(siteOffersTapToPay: Bool) async {
        // Given
        let sut = makeSUT(siteOffersTapToPay: siteOffersTapToPay, bluetooth: .denied, tapToPaySupported: false)

        // When
        let result = await sut.run()

        // Then
        #expect(!result.isSuccess)
        #expect(result.errorMessage == PaymentDeviceDiagnostics.Localization.noPaymentMethod)
        #expect(result.headline == PaymentDeviceDiagnostics.Localization.noPaymentMethodHeadline)
        #expect(result.suggestedAction == .openAppSettings)
    }

    @Test func test_run_when_site_offers_tap_to_pay_and_device_does_not_support_it_then_adds_note() async {
        // Given
        let sut = makeSUT(bluetooth: .notDetermined, tapToPaySupported: false)

        // When
        let result = await sut.run()

        // Then
        #expect(result.isSuccess)
        #expect(result.advisoryMessage == PaymentDeviceDiagnostics.Localization.tapToPayUnsupported)
        #expect(result.technicalDetails?.contains("tap_to_pay=unsupported") == true)
    }

    @Test func test_run_when_site_does_not_offer_tap_to_pay_then_has_no_tap_to_pay_note() async {
        // Given
        let sut = makeSUT(siteOffersTapToPay: false, tapToPaySupported: false)

        // When
        let result = await sut.run()

        // Then
        #expect(result.advisoryMessage == nil)
        #expect(result.technicalDetails?.contains("tap_to_pay=not_offered") == true)
    }

    @Test func test_run_when_connected_reader_battery_low_then_adds_note_without_reader_serial() async {
        // Given
        let reader = CardReader(serial: "SERIAL-123", vendorIdentifier: nil, name: "Reader name", status: .init(connected: true, remembered: true),
                                softwareVersion: nil, batteryLevel: 0.15, readerType: .wisepad3, locationId: nil)
        let sut = makeSUT(bluetooth: .allowed, tapToPaySupported: true, reader: reader)

        // When
        let result = await sut.run()

        // Then
        #expect(result.isSuccess)
        #expect(result.advisoryMessage == PaymentDeviceDiagnostics.Localization.lowBattery)
        #expect(result.technicalDetails?.contains("connected_reader=WISEPAD_3; battery=15%") == true)
        #expect(result.technicalDetails?.contains("SERIAL-123") == false)
        #expect(result.technicalDetails?.contains("Reader name") == false)
    }

    private func makeSUT(siteOffersTapToPay: Bool = true,
                         bluetooth: BluetoothAuthorization = .allowed,
                         tapToPaySupported: Bool = true,
                         reader: CardReader? = nil) -> PaymentDeviceDiagnostics {
        let determiner = MockCardReaderSupportDeterminer()
        determiner.shouldReturnSiteSupportsTapToPayReader = siteOffersTapToPay
        determiner.shouldReturnDeviceSupportsTapToPayReader = tapToPaySupported
        determiner.shouldReturnConnectedReader = reader
        return PaymentDeviceDiagnostics(supportDeterminer: determiner, bluetooth: MockBluetoothAuthorizationProvider(current: bluetooth))
    }
}

private struct MockBluetoothAuthorizationProvider: BluetoothAuthorizationProviding {
    let current: BluetoothAuthorization
}
