@testable import Hardware
import StripeTerminal
// This structs emulates the properties of StripeTerminal.Reader
// We can not mock StripeTerminal.Reader directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripeCardReader {
    let serialNumber: String
    let stripeId: String?
    let label: String?
    let status: ReaderNetworkStatus
    let deviceSoftwareVersion: String?
    let deviceType: DeviceType
    let batteryLevel: NSNumber?
}

extension MockStripeCardReader: StripeCardReader {}

extension MockStripeCardReader {
    static func stripeSDKTestReaders() -> [Self] {
        [bbpos(), verifone()]
    }

    static func bbpos() -> Self {
        MockStripeCardReader(serialNumber: "WPE-SIMULATOR-1",
                             stripeId: "SIMULATOR",
                             label: "Simulated WisePOS E",
                             status: .online,
                             deviceSoftwareVersion: "0.0.0.1",
                             deviceType: .chipper2X,
                             batteryLevel: NSNumber(floatLiteral: 0.5))
    }

    static func verifone() -> Self {
        MockStripeCardReader(serialNumber: "P400-SIMULATOR-1",
                             stripeId: "SIMULATOR",
                             label: "Simulated Verifone P400",
                             status: .online,
                             deviceSoftwareVersion: "3.0.1.17",
                             deviceType: .verifoneP400,
                             batteryLevel: NSNumber(floatLiteral: 0.5))
    }
}
