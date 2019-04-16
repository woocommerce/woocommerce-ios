import Foundation

public protocol FileStorage {
    func data(for fileURL: URL) throws -> Data
    func write(_ data: Data, to fileURL: URL) throws
}
