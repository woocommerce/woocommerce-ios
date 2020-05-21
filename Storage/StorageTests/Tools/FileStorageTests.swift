import XCTest
@testable import Storage

final class FileStorageTests: XCTestCase {
    private var fileURL: URL?
    private var subject: PListFileStorage?

    override func setUp() {
        super.setUp()
        subject = PListFileStorage()
        fileURL = Bundle(for: FileStorageTests.self)
            .url(forResource: "shipment-provider", withExtension: "plist")
    }

    override func tearDown() {
        fileURL = nil
        subject = nil
        super.tearDown()
    }

    func testFileIsLoaded() {
        var data: [PreselectedProvider]?
        XCTAssertNoThrow(data = try subject?.data(for: fileURL!))
        XCTAssertNotNil(data)
    }

    func testErrorIsTriggeredWhenFileFailsToLoad() {
        let url = URL(fileURLWithPath: "/non-existing-file")

        var data: Data?
        XCTAssertThrowsError(data = try subject?.data(for: url))
        XCTAssertNil(data)
    }

    func testErrorIsTriggeredWhenWritingFails() {
        let url = URL(fileURLWithPath: "/non-existing-file")
        let data = Data(count: 0)

        XCTAssertThrowsError(try subject?.write(data, to: url))
    }

    func testErrorIsTriggeredWhenFileFailsToDelete() {
        let url = URL(fileURLWithPath: "/non-existing-file")

        XCTAssertThrowsError(try subject?.deleteFile(at: url))
    }
}
