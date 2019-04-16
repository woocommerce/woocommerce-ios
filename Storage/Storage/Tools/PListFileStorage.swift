import Foundation

public final class PListFileStorage: FileStorage {
    public init() { }

    public func data(for fileURL: URL, completion: @escaping (Data?, Error?) -> Void) {
        do {
            let data = try Data(contentsOf: fileURL)
            completion(data, nil)
        } catch {
            let error = PListFileStorageErrors.fileLoadFailed
            completion(nil, error)
        }
    }
}

/// Errors
///
enum PListFileStorageErrors: Error {
    case fileLoadFailed
}
