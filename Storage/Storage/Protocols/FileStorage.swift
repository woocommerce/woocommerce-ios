import Foundation

public protocol FileStorage {
    func data(for fileURL: URL, completion: @escaping (Data?, Error?) -> Void)
}
