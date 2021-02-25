@testable import Hardware

struct MockCardReader {
    static func bbpos() -> CardReader {
        CardReader(serial: "WPE-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated WisePOS E",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: "0.0.0.1",
                   batteryLevel: 0.5,
                   readerType: .mobile)
    }

    static func verifone() -> CardReader {
        CardReader(serial: "P400-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated Verifone P400",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: "3.0.1.17",
                   batteryLevel: 0.5,
                   readerType: .counterTop)
    }
}
