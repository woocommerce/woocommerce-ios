import XCTest

extension XCTestCase {
    func XCTAssertPropertyCount<T>(_ instance: T,
                                   expectedCount: Int,
                                   messageHint: String? = nil,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
        let mirror = Mirror(reflecting: instance)
        let propertyCount = mirror.children.count

        var message = "Expected \(expectedCount) properties, but found \(propertyCount)."
        if let messageHint {
            message = "\(message) \(messageHint)"
        }

        XCTAssertEqual(propertyCount,
                       expectedCount,
                       message,
                       file: file,
                       line: line)
    }
}
