
import XCTest
import Foundation
@testable import WooCommerce

import Combine

/// Tests cases for `BehaviorSubject`
///
final class BehaviorSubjectTests: XCTestCase {

    func test_it_will_emit_values_to_an_observer() {
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

    func test_it_will_continuously_emit_values_to_an_observer() {
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

    func test_it_will_not_emit_values_before_the_subscription() {
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

    func test_it_will_emit_values_to_all_observers() {
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

    func test_it_will_not_emit_values_to_cancelled_observers() {
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

    func test_Combine_PassthroughSubject_emits_values_to_an_observer() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
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

    func test_Combine_PassthroughSubject_continuously_emits_values_to_an_observer() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
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

    func test_Combine_PassthroughSubject_does_not_emit_values_before_the_subscription() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
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

    func test_Combine_PassthroughSubject_emits_values_to_all_observers() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
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

    func test_Combine_PassthroughSubject_does_not_emit_values_to_cancelled_observers() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
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
