import XCTest
@testable import Storage

final class FileStorageTests: XCTestCase {
    private var fileURL: URL?
    private var subject: PListFileStorage?

    private let nonExistingFileURL = URL(fileURLWithPath: "/non-existing-file")

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

    func test_file_is_loaded() {
        var data: [PreselectedProvider]?
        XCTAssertNoThrow(data = try subject?.data(for: fileURL!))
        XCTAssertNotNil(data)
    }

    func test_error_is_triggered_when_file_fails_to_load() {
        var data: Data?
        XCTAssertThrowsError(data = try subject?.data(for: nonExistingFileURL))
        XCTAssertNil(data)
    }

    func test_error_is_triggered_when_writing_fails() {
        let data = Data(count: 0)

        XCTAssertThrowsError(try subject?.write(data, to: nonExistingFileURL))
    }

    func test_error_is_triggered_when_file_fails_to_delete() {
        XCTAssertThrowsError(try subject?.deleteFile(at: nonExistingFileURL))
    }
}
