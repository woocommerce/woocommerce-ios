import XCTest
@testable import Hardware

final class StripeCardReaderCacheTests: XCTestCase {
    func test_cache_is_initialized_empty() {
        let cache = StripeCardReaderCache()

        XCTAssertTrue(cache.cachedReaders.isEmpty)
    }

    func test_cache_contains_cached_readers_after_adding_one_reader() {
        let mockReader = MockStripeCardReader.bbpos()

        let cache = StripeCardReaderCache()
        cache.insert(mockReader)

        XCTAssertEqual(cache.cachedReaders.count, 1)
        XCTAssertEqual(cache.cachedReaders.first?.serialNumber, mockReader.serialNumber)
    }

    func test_cache_contains_cached_readers_after_adding_an_array_of_readers() {
        let mockReader = MockStripeCardReader.bbpos()

        let cache = StripeCardReaderCache()
        cache.insert([mockReader])

        XCTAssertEqual(cache.cachedReaders.count, 1)
        XCTAssertEqual(cache.cachedReaders.first?.serialNumber, mockReader.serialNumber)
    }

    func test_cache_matches_stripe_reader() {
        let mockStripeBBPOSReader = MockStripeCardReader.bbpos()
        let mockStripeVerifoneReader = MockStripeCardReader.verifone()

        let cache = StripeCardReaderCache()
        cache.insert([mockStripeBBPOSReader, mockStripeVerifoneReader, mockStripeVerifoneReader, mockStripeBBPOSReader])

        let cardReader = CardReader(serial: mockStripeBBPOSReader.serialNumber,
                                    vendorIdentifier: nil,
                                    name: nil,
                                    status: .init(connected: true, remembered: true),
                                    softwareVersion: nil,
                                    batteryLevel: 0.0,
                                    readerType: .mobile,
                                    stripeReader: mockStripeBBPOSReader)

        let readerMatching = cache.reader(matching: cardReader)

        XCTAssertEqual(mockStripeBBPOSReader.serialNumber, readerMatching?.serialNumber)
    }

    func test_cache_clears_cache() {
        let mockReader = MockStripeCardReader.bbpos()

        let cache = StripeCardReaderCache()
        cache.insert([mockReader])

        cache.clear()

        XCTAssertTrue(cache.cachedReaders.isEmpty)
    }
}
