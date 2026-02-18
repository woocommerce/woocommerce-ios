import Alamofire
import Foundation
import Testing
@testable import NetworkingCore

struct StreamableUploadSessionDelegateTests {

    private let urlSession: URLSession
    private let delegate: StreamableUploadSessionDelegate

    init() {
        delegate = StreamableUploadSessionDelegate()
        urlSession = URLSession(configuration: .default)
    }

    // MARK: - needNewBodyStream for data uploads

    @Test func test_needNewBodyStream_when_data_upload_then_returns_inputStream() {
        // Given
        let uploadData = Data("test upload data".utf8)
        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
        delegate.uploadStreamProvider.trackUploadable(.data(uploadData), for: task.taskIdentifier)

        // When
        let stream = callNeedNewBodyStream(task: task)

        // Then
        let readData = stream.flatMap { readAll(from: $0) }
        #expect(readData == uploadData)
    }

    // MARK: - needNewBodyStream for file uploads

    @Test func test_needNewBodyStream_when_file_upload_then_returns_inputStream() throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileData = Data("file upload test".utf8)
        try fileData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
        delegate.uploadStreamProvider.trackUploadable(.file(tempURL, shouldRemove: false), for: task.taskIdentifier)

        // When
        let stream = callNeedNewBodyStream(task: task)

        // Then
        let readData = stream.flatMap { readAll(from: $0) }
        #expect(readData == fileData)
    }

    // MARK: - needNewBodyStream for unknown tasks

    @Test func test_needNewBodyStream_when_unknown_task_then_returns_nil() {
        // Given
        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))

        // When
        let stream = callNeedNewBodyStream(task: task)

        // Then
        #expect(stream == nil)
    }

    // MARK: - Cleanup

    @Test func test_uploadable_when_removeAll_called_then_is_cleaned_up() {
        // Given
        let uploadData = Data("cleanup test".utf8)
        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
        delegate.uploadStreamProvider.trackUploadable(.data(uploadData), for: task.taskIdentifier)
        #expect(delegate.uploadStreamProvider.uploadable(for: task.taskIdentifier) != nil)

        // When
        delegate.uploadStreamProvider.removeAllUploadables()

        // Then
        #expect(delegate.uploadStreamProvider.uploadable(for: task.taskIdentifier) == nil)
    }
}

// MARK: - Helpers

private extension StreamableUploadSessionDelegateTests {

    func callNeedNewBodyStream(task: URLSessionTask) -> InputStream? {
        var receivedStream: InputStream?
        delegate.urlSession(urlSession, task: task, needNewBodyStream: { stream in
            receivedStream = stream
        })
        return receivedStream
    }

    func readAll(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        return data
    }
}
