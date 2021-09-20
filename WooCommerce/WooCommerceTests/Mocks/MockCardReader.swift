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

    static func bbposChipper2XBTNoVerNoBatt() -> CardReader {
        CardReader(serial: "WPE-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated POS E",
                   status: .init(connected: false, remembered: false),
                   softwareVersion: nil,
                   batteryLevel: nil,
                   readerType: .chipper,
                   locationId: "st_simulated")
    }
}
