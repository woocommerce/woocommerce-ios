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
        let expectation = self.expectation(description: "File must be loaded")

        subject?.data(for: fileURL!, completion: { data, error in
            if data != nil {
                expectation.fulfill()
            }
        })

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testErrorIsTriggeredWhenFileFailsToLoad() {
        let url = URL(string: "http://somewhere.on.the.internet")

        let expectation = self.expectation(description: "An error must be triggered")

        subject?.data(for: url!, completion: { data, error in
            if error != nil && data == nil {
                expectation.fulfill()
            }
        })

        waitForExpectations(timeout: 2, handler: nil)
    }
}
