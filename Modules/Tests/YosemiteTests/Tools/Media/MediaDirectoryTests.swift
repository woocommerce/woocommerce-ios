import XCTest
@testable import Yosemite

final class MediaDirectoryTests: XCTestCase {
    func testMediaDirectoryURLWithUploadsDirectory() {
        let name = "Media"
        let url = MediaDirectory.uploads.directoryURL(name: name)
        XCTAssertEqual(url.lastPathComponent, name)
        XCTAssertTrue(url.hasDirectoryPath)

        // The .uploads directory should be within the system Documents directory.
        let parentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        XCTAssert(url.absoluteString.hasPrefix(parentDirectory.absoluteString), "Media uploads directory URL has unexpected path.")
    }

    func testMediaDirectoryURLWithCacheDirectory() {
        let name = "Media"
        let url = MediaDirectory.cache.directoryURL(name: name)
        XCTAssertEqual(url.lastPathComponent, name)
        XCTAssertTrue(url.hasDirectoryPath)

        // The .cache directory should be within the system Caches directory.
        let parentDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        XCTAssert(url.absoluteString.hasPrefix(parentDirectory.absoluteString), "Media uploads directory URL has unexpected path.")
    }

    func testMediaDirectoryURLWithTemporaryDirectory() {
        let name = "Media"
        let url = MediaDirectory.temporary.directoryURL(name: name)
        XCTAssertEqual(url.lastPathComponent, name)
        XCTAssertTrue(url.hasDirectoryPath)

        // The .temporary directory should be within the system tmp directory.
        let parentDirectory = FileManager.default.temporaryDirectory
        XCTAssert(url.absoluteString.hasPrefix(parentDirectory.absoluteString), "Media uploads directory URL has unexpected path.")
    }
}
