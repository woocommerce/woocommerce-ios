import StripeTerminal

/// In memory, volatile cache
final class StripeCardReaderDiscoveryCache {
    /// CachedReaders. We will expose it for now until we have some more clarity on what we
    /// actually need from this class' API.
    /// Typed as StripeCardReader so that we can unit test this class, which makes the class
    /// well, testable, but on the other hand, makes the API less clear
    private(set) var cachedReaders: [StripeCardReader] = []

    func insert(_ reader: StripeCardReader) {
        cachedReaders.append(reader)
    }

    func insert(_ readers: [StripeCardReader]) {
        cachedReaders.append(contentsOf: readers)
    }

    func clear() {
        cachedReaders.removeAll()
    }

    func reader(matching: CardReader) -> StripeCardReader? {
        cachedReaders.filter {
            $0.serialNumber == matching.serial
        }.first
    }
}
