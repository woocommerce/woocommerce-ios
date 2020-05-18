
import XCTest
import Foundation
@testable import WooCommerce

import Combine

/// Tests cases for `PublishSubject`
///
final class PublishSubjectTests: XCTestCase {

    func testItWillEmitValuesToAnObserver() {
        // Given
        let subject = PublishSubject<String>()

        var emittedValues = [String]()
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // When
        subject.send("dicta")

        // Then
        XCTAssertEqual(emittedValues, ["dicta"])
    }

    func testItWillContinuouslyEmitValuesToAnObserver() {
        // Given
        let subject = PublishSubject<String>()

        var emittedValues = [String]()
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // When
        subject.send("dicta")
        subject.send("amet")
        subject.send("dolor")

        // Then
        XCTAssertEqual(emittedValues, ["dicta", "amet", "dolor"])
    }

    func testItWillNotEmitValuesBeforeTheSubscription() {
        // Given
        let subject = PublishSubject<String>()

        var emittedValues = [String]()

        // When
        // These are not emitted because there's no observer yet
        subject.send("dicta")
        subject.send("amet")

        // Add the observer
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // This will be emitted to the observer
        subject.send("dolor")

        // Then
        XCTAssertEqual(emittedValues, ["dolor"])
    }

    func testItWillEmitValuesToAllObservers() {
        // Given
        let subject = PublishSubject<String>()

        var emittedValues = [String]()

        // First observer
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }
        // Second observer
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // When
        subject.send("dicta")
        subject.send("amet")

        // Then
        // We'll receive two values for each observer
        XCTAssertEqual(emittedValues, ["dicta", "dicta", "amet", "amet"])
    }

    func testItWillNotEmitValuesToCancelledObservers() {
        // Given
        let subject = PublishSubject<String>()

        var emittedValues = [String]()
        let observationToken = subject.subscribe { value in
            emittedValues.append(value)
        }

        // This will be emitted because the observer is active
        subject.send("dicta")

        // When
        // Cancel the observer
        observationToken.cancel()

        // This will not be emitted anymore
        subject.send("amet")

        // Then
        XCTAssertEqual(emittedValues, ["dicta"])
    }

    // MARK: - Proof of Compatibility with Combine's PassthroughSubject

    func testCombinePassthroughSubjectEmitsValuesToAnObserver() {
        guard #available(iOS 13.0, *) else {
            return
        }

        // Given
        let subject = PassthroughSubject<String, Error>()
        var disposeBag = Set<AnyCancellable>()

        var emittedValues = [String]()
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // When
        subject.send("dicta")

        // Then
        XCTAssertEqual(emittedValues, ["dicta"])
    }

    func testCombinePassthroughSubjectContinuouslyEmitsValuesToAnObserver() {
        guard #available(iOS 13.0, *) else {
            return
        }

        // Given
        let subject = PassthroughSubject<String, Error>()
        var disposeBag = Set<AnyCancellable>()

        var emittedValues = [String]()
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // When
        subject.send("dicta")
        subject.send("amet")
        subject.send("dolor")

        // Then
        XCTAssertEqual(emittedValues, ["dicta", "amet", "dolor"])
    }

    func testCombinePassthroughSubjectDoesNotEmitValuesBeforeTheSubscription() {
        guard #available(iOS 13.0, *) else {
            return
        }

        // Given
        let subject = PassthroughSubject<String, Error>()
        var disposeBag = Set<AnyCancellable>()

        var emittedValues = [String]()

        // When
        // These are not emitted because there's no observer yet
        subject.send("dicta")
        subject.send("amet")

        // Add the observer
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // This will be emitted to the observer
        subject.send("dolor")

        // Then
        XCTAssertEqual(emittedValues, ["dolor"])
    }

    func testCombinePassthroughSubjectEmitsValuesToAllObservers() {
        guard #available(iOS 13.0, *) else {
            return
        }

        // Given
        let subject = PassthroughSubject<String, Error>()
        var disposeBag = Set<AnyCancellable>()

        var emittedValues = [String]()

        // First observer
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // Second observer
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // When
        subject.send("dicta")
        subject.send("amet")

        // Then
        // We'll receive two values for each observer
        XCTAssertEqual(emittedValues, ["dicta", "dicta", "amet", "amet"])
    }

    func testCombinePassthroughSubjectDoesNotEmitValuesToCancelledObservers() {
        guard #available(iOS 13.0, *) else {
            return
        }

        // Given
        let subject = PassthroughSubject<String, Error>()

        var emittedValues = [String]()
        let cancellable = subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }

        // This will be emitted because the observer is active
        subject.send("dicta")

        // When
        // Cancel the observer
        cancellable.cancel()

        // This will not be emitted anymore
        subject.send("amet")

        // Then
        XCTAssertEqual(emittedValues, ["dicta"])
    }
}
