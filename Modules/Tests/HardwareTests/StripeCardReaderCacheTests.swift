import Testing
@testable import Hardware

struct `Stripe Card Reader Cache Tests` {
    @Test func `cache is initialized empty`() {
        let cache = StripeCardReaderDiscoveryCache()

        #expect(cache.cachedReaders.isEmpty)
    }

    @Test func `cache contains cached readers after adding one reader`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert(mockReader)

        #expect(cache.cachedReaders.count == 1)
        #expect(cache.cachedReaders.first?.serialNumber == mockReader.serialNumber)
    }

    @Test func `cache contains cached readers after adding an array of readers`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert([mockReader])

        #expect(cache.cachedReaders.count == 1)
        #expect(cache.cachedReaders.first?.serialNumber == mockReader.serialNumber)
    }

    @Test func `cache matches stripe reader`() {
        let mockStripeBBPOSReader = MockStripeCardReader.bbposChipper2XBT()
        let mockStripeM2Reader = MockStripeCardReader.stripeM2()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert([mockStripeBBPOSReader, mockStripeM2Reader, mockStripeM2Reader, mockStripeBBPOSReader])

        let cardReader = CardReader(serial: mockStripeBBPOSReader.serialNumber,
                                    vendorIdentifier: nil,
                                    name: nil,
                                    status: .init(connected: true, remembered: true),
                                    softwareVersion: nil,
                                    batteryLevel: 0.0,
                                    readerType: .chipper,
                                    locationId: "st_simulated")

        let readerMatching = cache.reader(matching: cardReader)

        #expect(mockStripeBBPOSReader.serialNumber == readerMatching?.serialNumber)
    }

    @Test func `cache clears cache`() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert([mockReader])

        cache.clear()

        #expect(cache.cachedReaders.isEmpty)
    }
}
