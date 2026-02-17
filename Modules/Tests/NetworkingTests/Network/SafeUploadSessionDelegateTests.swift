import Alamofire
import XCTest
@testable import NetworkingCore

final class SafeUploadSessionDelegateTests: XCTestCase {

    private var urlSession: URLSession!
    private var delegate: SafeUploadSessionDelegate!

    override func setUp() {
        super.setUp()
        delegate = SafeUploadSessionDelegate()
        urlSession = URLSession(configuration: .default)
    }

    override func tearDown() {
        urlSession = nil
        delegate = nil
        super.tearDown()
    }

    // MARK: - needNewBodyStream for data uploads

    func test_needNewBodyStream_returns_inputStream_for_data_upload() {
        // Given
        let uploadData = Data("test upload data".utf8)
        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
        delegate.uploadStreamProvider.trackUploadable(.data(uploadData), for: task.taskIdentifier)

        // When
        let stream = waitForStream(task: task)

        // Then
        XCTAssertNotNil(stream)
        if let stream {
            let readData = readAll(from: stream)
            XCTAssertEqual(readData, uploadData)
        }
    }

    // MARK: - needNewBodyStream for file uploads

    func test_needNewBodyStream_returns_inputStream_for_file_upload() throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileData = Data("file upload test".utf8)
        try fileData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
        delegate.uploadStreamProvider.trackUploadable(.file(tempURL, shouldRemove: false), for: task.taskIdentifier)

        // When
        let stream = waitForStream(task: task)

        // Then
        XCTAssertNotNil(stream)
        if let stream {
            let readData = readAll(from: stream)
            XCTAssertEqual(readData, fileData)
        }
    }

    // MARK: - needNewBodyStream for unknown tasks

    func test_needNewBodyStream_returns_nil_for_unknown_task() {
        // Given — a task not tracked by the provider
        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))

        // When
        let stream = waitForStream(task: task)

        // Then
        XCTAssertNil(stream)
    }

    // MARK: - Cleanup

    func test_uploadable_is_cleaned_up_after_removeAll() {
        // Given
        let uploadData = Data("cleanup test".utf8)
        let task = urlSession.dataTask(with: URLRequest(url: URL(string: "https://example.com")!))
        delegate.uploadStreamProvider.trackUploadable(.data(uploadData), for: task.taskIdentifier)

        // Verify tracking is present
        XCTAssertNotNil(delegate.uploadStreamProvider.uploadable(for: task.taskIdentifier))

        // When
        delegate.uploadStreamProvider.removeAllUploadables()

        // Then
        XCTAssertNil(delegate.uploadStreamProvider.uploadable(for: task.taskIdentifier))
    }
}

// MARK: - Helpers

private extension SafeUploadSessionDelegateTests {

    func waitForStream(task: URLSessionTask) -> InputStream? {
        var receivedStream: InputStream?
        let streamReceived = expectation(description: "Stream callback")

        delegate.urlSession(urlSession, task: task, needNewBodyStream: { stream in
            receivedStream = stream
            streamReceived.fulfill()
        })

        wait(for: [streamReceived], timeout: 5)
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
