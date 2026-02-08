import Testing
@testable import Hardware

/// Tests the mapping between CardReader and SCPReader
@Suite("Card Reader Tests")
struct CardReaderTests {
    @Test func test_card_reader_maps_serial_number() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.serial == mockReader.serialNumber)
    }

    @Test func test_card_reader_maps_stripe_id() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.vendorIdentifier == mockReader.stripeId)
    }

    @Test func test_card_reader_maps_label() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.name == mockReader.label)
    }

    @Test func test_card_reader_maps_connected_status() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.status.connected)
    }

    @Test func test_card_reader_maps_sofware_version() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.softwareVersion == mockReader.deviceSoftwareVersion)
    }

    @Test func test_card_reader_maps_battery_level() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.batteryLevel == mockReader.batteryLevel?.floatValue)
    }

    @Test func test_card_reader_maps_reader_type_for_bbpos() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.readerType == .chipper)
    }

    @Test func test_card_reader_maps_reader_type_for_m2() {
        let mockReader = MockStripeCardReader.stripeM2()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.readerType == .stripeM2)
    }

    @Test func test_card_reader_maps_reader_type_for_wisepad3() {
        let mockReader = MockStripeCardReader.wisepad3()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.readerType == .wisepad3)
    }
}
