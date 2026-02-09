import Testing
@testable import Hardware

/// Tests the mapping between CardReader and SCPReader
struct `Card Reader Tests` {
    @Test func `card reader maps serial number`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.serial == mockReader.serialNumber)
    }

    @Test func `card reader maps stripe id`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.vendorIdentifier == mockReader.stripeId)
    }

    @Test func `card reader maps label`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.name == mockReader.label)
    }

    @Test func `card reader maps connected status`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.status.connected)
    }

    @Test func `card reader maps sofware version`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.softwareVersion == mockReader.deviceSoftwareVersion)
    }

    @Test func `card reader maps battery level`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.batteryLevel == mockReader.batteryLevel?.floatValue)
    }

    @Test func `card reader maps reader type for bbpos`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.readerType == .chipper)
    }

    @Test func `card reader maps reader type for m2`() {
        let mockReader = MockStripeCardReader.stripeM2()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.readerType == .stripeM2)
    }

    @Test func `card reader maps reader type for wisepad3`() {
        let mockReader = MockStripeCardReader.wisepad3()
        let cardReader = CardReader(reader: mockReader)

        #expect(cardReader.readerType == .wisepad3)
    }
}
