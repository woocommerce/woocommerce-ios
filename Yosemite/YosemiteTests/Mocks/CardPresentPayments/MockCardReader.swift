@testable import Hardware

struct MockCardReader {
    static func bbposChipper2XBT() -> CardReader {
        CardReader(serial: "WPE-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated POS E",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001",
                   batteryLevel: 0.5,
                   readerType: .chipper,
                   locationId: "st_simulated")
    }

    static func verifoneP400() -> CardReader {
        CardReader(serial: "P400-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated Verifone P400",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: "3.0.1.17",
                   batteryLevel: 1.0,
                   readerType: .other,
                   locationId: "st_simulated")
    }
}
