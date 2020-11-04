import XCTest
@testable import WooCommerce

class AsyncDictionaryTests: XCTestCase {
    private let asyncDictionary = AsyncDictionary<Int, String>()

    func testAsyncValueCalculationAndUpdate() {
        let key = 107
        let value = "Woo!"

        let expectationForOperation = self.expectation(description: "Wait for operation to be called not on the main thread")
        let operation = { () -> String in
            XCTAssertFalse(Thread.current.isMainThread)
            expectationForOperation.fulfill()
            return value
        }
        let expectationForOnCompletion = self.expectation(description: "Wait for completion callback to be called on the main thread")
        let onCompletion = { (updatedValue: String?) in
            XCTAssertEqual(updatedValue, value)
            XCTAssertTrue(Thread.current.isMainThread)
            expectationForOnCompletion.fulfill()
        }
        asyncDictionary.calculate(forKey: key, operation: operation, onCompletion: onCompletion)
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertEqual(asyncDictionary.value(forKey: key), value)
    }

    func testClearingDictionary() {
        let key = 107
        let value = "Woo!"

        var isDictionaryCleared = false
        let operation1 = { () -> String in
            while !isDictionaryCleared {
                continue
            }
            return value
        }
        let expectationForOnCompletion = self.expectation(description: "Wait for completion callback")
        let onCompletion = { (updatedValue: String?) in
            XCTAssertNil(updatedValue)
            XCTAssertTrue(Thread.current.isMainThread)
            expectationForOnCompletion.fulfill()
        }
        asyncDictionary.calculate(forKey: key, operation: operation1, onCompletion: onCompletion)
        asyncDictionary.clear()
        isDictionaryCleared = true
        XCTAssertNil(asyncDictionary.value(forKey: key))
        waitForExpectations(timeout: 0.1, handler: nil)
        // After the async operation completes, the dictionary value should remain nil.
        XCTAssertNil(asyncDictionary.value(forKey: key))
    }

    func testAsyncUpdatesWhereTheFirstOperationFinishesLast() {
        let key = 107
        let value1 = "Woah!"
        let value2 = "Woo!"

        // The first operation will finish after the second operation finishes.
        var isValue2Updated = false
        let operation1 = { () -> String in
            while !isValue2Updated {
                continue
            }
            return value1
        }
        let expectationForOnOperation1Completion = self.expectation(description: "Wait for completion callback for the first operation")
        let onOperation1Completion = { (updatedValue: String?) in
            XCTAssertNil(updatedValue)
            XCTAssertTrue(Thread.current.isMainThread)
            expectationForOnOperation1Completion.fulfill()
        }
        asyncDictionary.calculate(forKey: key, operation: operation1, onCompletion: onOperation1Completion)

        let operation2 = { () -> String in
            return value2
        }
        let onOperation2Completion = { (updatedValue: String?) in
            XCTAssertEqual(updatedValue, value2)
            XCTAssertTrue(Thread.current.isMainThread)
            isValue2Updated = true
        }

        asyncDictionary.calculate(forKey: key, operation: operation2, onCompletion: onOperation2Completion)
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(asyncDictionary.value(forKey: key), value2)
    }
}
