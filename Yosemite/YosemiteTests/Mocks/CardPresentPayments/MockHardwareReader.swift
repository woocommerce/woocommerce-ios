@testable import Hardware
struct MockHardwareReader {
    static func bbpos() -> Hardware.CardReader {
        CardReader(serial: "WPE-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated WisePOS E",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: "0.0.0.1",
                   batteryLevel: 0.5,
                   readerType: .mobile)
    }

    static func verifone() -> Hardware.CardReader {
        CardReader(serial: "P400-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated Verifone P400",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: "3.0.1.17",
                   batteryLevel: 0.5,
                   readerType: .counterTop)
    }
}
