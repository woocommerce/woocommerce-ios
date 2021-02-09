/// Implement this protocol to handle a continually updating list of discovered readers
public protocol CardReaderServiceDelegate: AnyObject {
    func didUpdateDiscoveredReaders(_ readers: [CardReader])
}
