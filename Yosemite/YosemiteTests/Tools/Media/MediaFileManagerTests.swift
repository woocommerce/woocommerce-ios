import XCTest
@testable import Yosemite

final class MediaFileManagerTests: XCTestCase {
    func testCreatingLocalMediaURL() {
        do {
            let basename = "media-service-test-sample"
            let pathExtension = "jpg"
            let expected = "\(basename).\(pathExtension)"

            let fileManager = MediaFileManager()

            var url = try fileManager.createLocalMediaURL(withFilename: basename, fileExtension: pathExtension)
            XCTAssertEqual(url.lastPathComponent, expected)

            url = try fileManager.createLocalMediaURL(withFilename: expected, fileExtension: pathExtension)
            XCTAssertEqual(url.lastPathComponent, expected)

            url = try fileManager.createLocalMediaURL(withFilename: basename + ".png", fileExtension: pathExtension)
            XCTAssertEqual(url.lastPathComponent, expected)

            url = try fileManager.createLocalMediaURL(withFilename: basename, fileExtension: nil)
            XCTAssertEqual(url.lastPathComponent, basename)

            url = try fileManager.createLocalMediaURL(withFilename: expected, fileExtension: nil)
            XCTAssertEqual(url.lastPathComponent, expected)
        } catch {
            XCTFail("Error creating local media URL: \(error)")
        }
    }

    func testRemovingLocalMediaAtURL() {
        do {
            let fileManager = MockupFileManager()
            let data = Data()
            let mediaFileManager = MediaFileManager(fileManager: fileManager)
            let localURL = try mediaFileManager.createLocalMediaURL(withFilename: "hello", fileExtension: "txt")

            XCTAssertTrue(fileManager.createFile(atPath: localURL.path, contents: data))
            XCTAssertTrue(fileManager.fileExists(atPath: localURL.path))

            try mediaFileManager.removeLocalMedia(at: localURL)
            XCTAssertFalse(fileManager.fileExists(atPath: localURL.path))
        } catch {
            XCTFail("\(error)")
        }
    }
}
