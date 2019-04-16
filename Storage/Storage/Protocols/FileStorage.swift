import Foundation

public protocol FileStorage {
    func data(for fileURL: URL) throws -> Data
}
