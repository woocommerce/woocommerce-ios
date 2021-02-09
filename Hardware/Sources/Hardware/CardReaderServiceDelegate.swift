/// Implement this protocol to handle a continually updating list of discovered readers
/// This is a great candidate to be removed and implemented via a
/// Combine Publisher. We will keep it here for this first iteration though.
public protocol CardReaderServiceDelegate: AnyObject {
    func didUpdateDiscoveredReaders(_ readers: [CardReader])
}
