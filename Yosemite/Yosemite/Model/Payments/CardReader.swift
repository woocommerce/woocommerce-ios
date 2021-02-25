public struct CardReader {
    public let name: String?
    public let serialNumber: String
}


extension CardReader: Identifiable {
    public var id: String {
        serialNumber
    }
}
