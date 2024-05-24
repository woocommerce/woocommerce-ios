import Storage

final class MockInMemoryStorage: FileStorage {
    private(set) var data: [URL: Codable] = [:]

    func data<T>(for fileURL: URL) throws -> T where T: Decodable {
        guard let data = data[fileURL] as? T else {
            throw Errors.readFailed
        }
        return data
    }

    func write<T>(_ data: T, to fileURL: URL) throws where T: Encodable {
        self.data[fileURL] = data as? Codable
    }

    func deleteFile(at fileURL: URL) throws {
        data.removeValue(forKey: fileURL)
    }

    enum Errors: Error {
        case readFailed
    }
}
