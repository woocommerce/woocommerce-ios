import Foundation
import Yosemite
import enum Hardware.CardReaderType
import enum WooFoundation.BluetoothAuthorization
import protocol WooFoundation.BluetoothAuthorizationProviding
import struct WooFoundation.CoreBluetoothAuthorizationProvider

/// Reads this device's Bluetooth permission, Tap to Pay support and connected reader without scanning or connecting.
@MainActor
struct PaymentDeviceDiagnostics {
    let supportDeterminer: CardReaderSupportDetermining
    var bluetooth: BluetoothAuthorizationProviding = CoreBluetoothAuthorizationProvider()

    func run() async -> SupportDiagnosticsService.Result {
        let bluetoothAuthorization = bluetooth.current
        let offersTapToPay = supportDeterminer.siteSupportsTapToPayReader()
        let supportsTapToPay = offersTapToPay ? await supportDeterminer.deviceSupportsTapToPayReader() : false
        let reader = await supportDeterminer.connectedReader()

        var notes: [String] = []
        if bluetoothAuthorization == .denied {
            notes.append(Localization.bluetoothDenied)
        }
        if offersTapToPay && !supportsTapToPay {
            notes.append(Localization.tapToPayUnsupported)
        }
        if let reader, reader.readerType != .tapToPay, let battery = reader.batteryLevel, battery < Constants.lowBattery {
            notes.append(Localization.lowBattery)
        }

        let details = [
            "checked_at=\(ISO8601DateFormatter().string(from: Date()))",
            "bluetooth=\(bluetoothAuthorization.detail)",
            "tap_to_pay=\(offersTapToPay ? (supportsTapToPay ? "supported" : "unsupported") : "not_offered")",
            "connected_reader=\(reader.map { $0.readerType.model } ?? "none")",
            reader?.batteryLevel.map { "battery=\(Int(($0 * 100).rounded()))%" }
        ].compactMap { $0 }.joined(separator: "; ")

        guard bluetoothAuthorization != .denied || supportsTapToPay else {
            return .failure(test: .paymentDevice, failure: .init(errorMessage: Localization.noPaymentMethod,
                                                                 technicalDetails: details,
                                                                 suggestedAction: .openAppSettings,
                                                                 headline: Localization.noPaymentMethodHeadline))
        }
        return .init(test: .paymentDevice,
                     isSuccess: true,
                     errorMessage: nil,
                     technicalDetails: details,
                     suggestedAction: bluetoothAuthorization == .denied ? .openAppSettings : nil,
                     advisoryMessage: notes.isEmpty ? nil : notes.joined(separator: "\n\n"))
    }
}

private extension PaymentDeviceDiagnostics {
    enum Constants {
        static let lowBattery: Float = 0.2
    }
}

private extension BluetoothAuthorization {
    var detail: String {
        switch self {
        case .notDetermined:
            return "not_determined"
        case .denied:
            return "denied"
        case .allowed:
            return "allowed"
        }
    }
}

extension PaymentDeviceDiagnostics {
    enum Localization {
        static let title = NSLocalizedString(
            "paymentDeviceDiagnostics.title",
            value: "Checking this device and card reader",
            comment: "Progress step in support chat while the app checks Bluetooth access, Tap to Pay support and the connected card reader"
        )
        static let bluetoothDenied = NSLocalizedString(
            "paymentDeviceDiagnostics.bluetoothDenied",
            value: "Bluetooth access is off for this app, so card readers cannot connect. Turn it on in the Settings app, under " +
                "Privacy & Security, then Bluetooth.",
            comment: "Note in support chat when the app does not have Bluetooth permission, which card readers need"
        )
        static let tapToPayUnsupported = NSLocalizedString(
            "paymentDeviceDiagnostics.tapToPayUnsupported",
            value: "This device cannot use Tap to Pay on iPhone. Use a card reader, or an iPhone that supports Tap to Pay.",
            comment: "Note in support chat when the store country offers Tap to Pay but this device does not support it"
        )
        static let lowBattery = NSLocalizedString(
            "paymentDeviceDiagnostics.lowBattery",
            value: "The connected card reader has a low battery. Charge it before you take payments.",
            comment: "Note in support chat when the connected card reader battery is below 20 percent"
        )
        static let noPaymentMethodHeadline = NSLocalizedString(
            "paymentDeviceDiagnostics.noPaymentMethod.headline",
            value: "Bluetooth access is off",
            comment: "Headline of the support chat result when Bluetooth permission is off and Tap to Pay is not available on this device"
        )
        static let noPaymentMethod = NSLocalizedString(
            "paymentDeviceDiagnostics.noPaymentMethod.message",
            value: "Card readers cannot connect, and Tap to Pay is not available on this device. Turn on Bluetooth for this app in Settings.",
            comment: "Support chat result when Bluetooth permission is off and Tap to Pay is not available on this device"
        )
    }
}
