import XCTest
@testable import WooCommerce

class AsyncDictionaryTests: XCTestCase {
    private let asyncDictionary = AsyncDictionary<Int, String>()

    func testAsyncValueCalculationAndUpdate() {
        let key = 107
        let value = "Woo!"

        let expectationForCalculation = self.expectation(description: "Wait for calculation to be called not on the main thread")
        let calculation = { () -> String in
            XCTAssertFalse(Thread.current.isMainThread)
            expectationForCalculation.fulfill()
            return value
        }
        let expectationForOnUpdate = self.expectation(description: "Wait for update callback to be called on the main thread")
        let onUpdate = { (updatedValue: String) in
            XCTAssertEqual(updatedValue, value)
            XCTAssertTrue(Thread.current.isMainThread)
            expectationForOnUpdate.fulfill()
        }
        asyncDictionary.calculate(forKey: key, operation: calculation, onCompletion: onUpdate)
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertEqual(asyncDictionary.value(forKey: key), value)
    }
}
