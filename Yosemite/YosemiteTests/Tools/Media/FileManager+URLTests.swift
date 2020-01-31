import XCTest
@testable import Yosemite

final class FileManager_URLTests: XCTestCase {
    private lazy var fileManager = MockupFileManager()

    func testCreatingIncrementalFilenames() {
        let filename = "hello"
        let fileExtension = "txt"

        let url = fileManager.temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
            .appendingPathExtension(fileExtension)
        let originalURL = fileManager.createIncrementalFilenameIfNeeded(url: url)
        XCTAssertEqual(originalURL.lastPathComponent, "\(filename).\(fileExtension)")

        createMockData(at: url)

        let urlCopy1 = fileManager.createIncrementalFilenameIfNeeded(url: url)
        XCTAssertEqual(urlCopy1.lastPathComponent, "\(filename)-1.\(fileExtension)")

        createMockData(at: urlCopy1)

        let urlCopy2 = fileManager.createIncrementalFilenameIfNeeded(url: url)
        XCTAssertEqual(urlCopy2.lastPathComponent, "\(filename)-2.\(fileExtension)")
    }
}

private extension FileManager_URLTests {
    func createMockData(at fileURL: URL) {
        _ = fileManager.createFile(atPath: fileURL.path, contents: Data())
    }
}
