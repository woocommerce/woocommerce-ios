import XCTest
@testable import WooCommerce

final class Dictionary_LoggingTests: XCTestCase {
    func testSerializingValuesForAnEmptyDictionary() {
        // Arrange
        let dictionary: [String: Any] = [:]

        // Action
        let serializableDictionary = dictionary.serializeValuesForLoggingIfNeeded()

        // Assert
        XCTAssertTrue(JSONSerialization.isValidJSONObject(serializableDictionary))
        XCTAssertEqual(serializableDictionary.count, 0)
    }

    func testSerializingValuesForADictionaryWithNSErrors() {
        // Arrange
        let error = NSError(domain: "Testing crash logging in Sentry on Reviews tab launch",
                            code: 100,
                            userInfo: ["reason": "Testing only"])
        let error1Key = "Error 1"
        let error2Key = "Error 2"
        let dictionary: [String: Any] = [error1Key: error, error2Key: error, "message": "hello"]

        // Action
        let serializableDictionary = dictionary.serializeValuesForLoggingIfNeeded()

        // Assert
        XCTAssertTrue(JSONSerialization.isValidJSONObject(serializableDictionary))
        XCTAssertEqual(serializableDictionary.count, 3)
    }

    func testSerializingValuesForADictionaryWithUnsupportedType() {
        // Arrange
        struct Value {
            let message: String
        }
        let dictionary: [String: Any] = ["test": Value(message: "😃")]

        // Action
        let serializableDictionary = dictionary.serializeValuesForLoggingIfNeeded()

        // Assert
        XCTAssertTrue(JSONSerialization.isValidJSONObject(serializableDictionary))
        XCTAssertEqual(serializableDictionary.count, 1)
    }
}
