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
    }

    func testFileIsLoaded() {
        XCTAssertNoThrow(try subject?.data(for: fileURL!))
    }

    func testErrorIsTriggeredWhenFileFailsToLoad() {
        let url = URL(string: "http://somewhere.on.the.internet")

        XCTAssertThrowsError(try subject?.data(for: url!))
    }
}
