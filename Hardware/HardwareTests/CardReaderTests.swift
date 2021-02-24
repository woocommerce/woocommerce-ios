import XCTest
@testable import Hardware

/// Tests the mapping between CardReader and SCPReader
final class CardReaderTests: XCTestCase {
    func test_card_reader_maps_serial_number() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.serial, mockReader.serialNumber)
    }

    func test_card_reader_maps_stripe_id() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.vendorIdentifier, mockReader.stripeId)
    }

    func test_card_reader_maps_label() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.name, mockReader.label)
    }

    func test_card_reader_maps_connected_status() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertTrue(cardReader.status.connected)
    }

    func test_card_reader_maps_sofware_version() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.softwareVersion, mockReader.deviceSoftwareVersion)
    }

    func test_card_reader_maps_battery_level() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.batteryLevel, mockReader.batteryLevel?.floatValue)
    }

    func test_card_reader_maps_reader_type_for_bbpos() {
        let mockReader = MockStripeCardReader.bbpos()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.readerType, .mobile)
    }

    func test_card_reader_maps_reader_type_for_verifone() {
        let mockReader = MockStripeCardReader.verifone()
        let cardReader = CardReader(reader: mockReader)

        XCTAssertEqual(cardReader.readerType, .counterTop)
    }
}
