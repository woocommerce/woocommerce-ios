import Alamofire
import Foundation
import Testing
@testable import NetworkingCore

struct StreamableUploadSessionDelegateTests {

    private let urlSession = URLSession(configuration: .default)
    private let delegate = StreamableUploadSessionDelegate()

    @Test(arguments: ["data", "file"])
    func test_needNewBodyStream_when_tracked_upload_then_returns_original_bytes(type: String) throws {
        let expectedData = Data("test upload content".utf8)
        let task = makeTask()
        var tempURL: URL?
        defer { tempURL.flatMap { try? FileManager.default.removeItem(at: $0) } }

        if type == "data" {
            delegate.uploadStreamProvider.trackUploadable(.data(expectedData), for: task.taskIdentifier)
        } else {
            tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try expectedData.write(to: tempURL!)
            delegate.uploadStreamProvider.trackUploadable(.file(tempURL!, shouldRemove: false), for: task.taskIdentifier)
        }

        let stream = callNeedNewBodyStream(task: task)
        #expect(stream != nil)
        #expect(Data(reading: stream!) == expectedData)
    }

    @Test func test_needNewBodyStream_when_unknown_task_then_returns_nil() {
        #expect(callNeedNewBodyStream(task: makeTask()) == nil)
    }

    @Test func test_uploadable_when_removeAll_called_then_is_cleaned_up() {
        // Given
        let task = makeTask()
        delegate.uploadStreamProvider.trackUploadable(.data(Data("x".utf8)), for: task.taskIdentifier)
        #expect(delegate.uploadStreamProvider.uploadable(for: task.taskIdentifier) != nil)

        // When
        delegate.uploadStreamProvider.removeAllUploadables()

        // Then
        #expect(delegate.uploadStreamProvider.uploadable(for: task.taskIdentifier) == nil)
    }
}

// MARK: - Helpers

private extension StreamableUploadSessionDelegateTests {

    func makeTask() -> URLSessionTask {
        urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
    }

    func callNeedNewBodyStream(task: URLSessionTask) -> InputStream? {
        var result: InputStream?
        delegate.urlSession(urlSession, task: task, needNewBodyStream: { result = $0 })
        return result
    }
}

private extension Data {
    init(reading stream: InputStream) {
        self.init()
        stream.open()
        defer { stream.close() }
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 1024)
            guard count > 0 else { break }
            append(buffer, count: count)
        }
    }
}
