import XCTest
@testable import Hardware

/// Tests the mapping between CardReader and SCPReader
final class CardReaderTests: XCTestCase {
    func test_card_reader_maps_serial_number() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.serial, mockReader.serialNumber)
    }

    func test_card_reader_maps_stripe_id() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.vendorIdentifier, mockReader.stripeId)
    }

    func test_card_reader_maps_label() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.name, mockReader.label)
    }

    func test_card_reader_maps_connected_status() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertTrue(cardReader.status.connected)
    }

    func test_card_reader_maps_sofware_version() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.softwareVersion, mockReader.deviceSoftwareVersion)
    }

    func test_card_reader_maps_battery_level() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.batteryLevel, mockReader.batteryLevel?.floatValue)
    }

    func test_card_reader_maps_reader_type_for_bbpos() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.readerType, .chipper)
    }

    func test_card_reader_maps_reader_type_for_m2() {
        let mockReader = MockStripeCardReader.stripeM2()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.readerType, .stripeM2)
    }

    func test_card_reader_maps_reader_type_for_wisepad3() {
        let mockReader = MockStripeCardReader.wisepad3()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.readerType, .wisepad3)
    }

    func test_card_reader_maps_reader_type_for_verifone() {
        let mockReader = MockStripeCardReader.verifoneP400()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.readerType, .other)
    }
}
