import Testing
@testable import Hardware

@Suite("Stripe Card Reader Cache Tests")
struct StripeCardReaderCacheTests {
    @Test func test_cache_is_initialized_empty() {
        let cache = StripeCardReaderDiscoveryCache()

        #expect(cache.cachedReaders.isEmpty)
    }

    @Test func test_cache_contains_cached_readers_after_adding_one_reader() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert(mockReader)

        #expect(cache.cachedReaders.count == 1)
        #expect(cache.cachedReaders.first?.serialNumber == mockReader.serialNumber)
    }

    @Test func test_cache_contains_cached_readers_after_adding_an_array_of_readers() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert([mockReader])

        #expect(cache.cachedReaders.count == 1)
        #expect(cache.cachedReaders.first?.serialNumber == mockReader.serialNumber)
    }

    @Test func test_cache_matches_stripe_reader() {
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

    @Test func test_cache_clears_cache() {
        let mockReader = MockStripeCardReader.bbposChipper2XBT()

        let cache = StripeCardReaderDiscoveryCache()
        cache.insert([mockReader])

        cache.clear()

        #expect(cache.cachedReaders.isEmpty)
    }
}
