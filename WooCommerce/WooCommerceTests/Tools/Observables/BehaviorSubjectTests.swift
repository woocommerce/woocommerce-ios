
import XCTest
import Foundation
@testable import WooCommerce

import Combine

/// Tests cases for `BehaviorSubject`
///
final class BehaviorSubjectTests: XCTestCase {

    func test_it_will_emit_the_initial_value_to_an_observer() {
        // Given
        let subject = BehaviorSubject("dolorem")

        // When
        var emittedValues = [String]()
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // Then
        XCTAssertEqual(emittedValues, ["dolorem"])
    }

    func test_it_will_emit_the_last_value_before_the_subscription() {
        // Given
        let subject = BehaviorSubject("dolorem")

        // This will be emitted instead of "dolorem" when the subscription happens below
        // because it's the last value.
        subject.send("recusandae")

        // When
        var emittedValues = [String]()
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // Then
        XCTAssertEqual(emittedValues, ["recusandae"])
    }

    func test_it_will_emit_values_to_an_observer() {
        // Given
        let subject = BehaviorSubject("consequatur")

        var emittedValues = [String]()
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // When
        subject.send("dicta")

        // Then
        XCTAssertEqual(emittedValues, ["consequatur", "dicta"])
    }

    func test_it_will_continuously_emit_values_to_an_observer() {
        // Given
        let subject = BehaviorSubject("exercitationem")

        var emittedValues = [String]()
        _ = subject.subscribe { value in
            emittedValues.append(value)
        }

        // When
        subject.send("dicta")
        subject.send("amet")
        subject.send("dolor")

        // Then
        XCTAssertEqual(emittedValues, ["exercitationem", "dicta", "amet", "dolor"])
    }

    func test_it_will_emit_values_to_all_observers() {
        // Given
        let subject = BehaviorSubject("provident")

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
        XCTAssertEqual(emittedValues, ["provident", "provident", "dicta", "dicta", "amet", "amet"])
    }

    func test_it_will_not_emit_values_to_cancelled_observers() {
        // Given
        // "dicta" will be emitted because it is the initial value
        let subject = BehaviorSubject("dicta")

        var emittedValues = [String]()
        let observationToken = subject.subscribe { value in
            emittedValues.append(value)
        }

        // When
        // Cancel the observer
        observationToken.cancel()

        // This will not be emitted anymore
        subject.send("amet")

        // Then
        XCTAssertEqual(emittedValues, ["dicta"])
    }

    // MARK: - Proof of Compatibility with Combine's CurrentValueSubject

    func test_Combine_CurrentValueSubject_will_emit_the_initial_value_to_an_observer() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
            return
        }

        // Given
        let subject = CurrentValueSubject<String, Error>("dolorem")
        var disposeBag = Set<AnyCancellable>()

        // When
        var emittedValues = [String]()
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // Then
        XCTAssertEqual(emittedValues, ["dolorem"])
    }

    func test_Combine_CurrentValueSubject_will_emit_the_last_value_before_the_subscription() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
            return
        }

        // Given
        let subject = CurrentValueSubject<String, Error>("dolorem")
        var disposeBag = Set<AnyCancellable>()

        // This will be emitted instead of "dolorem" when the subscription happens below
        // because it's the last value.
        subject.send("recusandae")

        // When
        var emittedValues = [String]()
        subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }.store(in: &disposeBag)

        // Then
        XCTAssertEqual(emittedValues, ["recusandae"])
    }

    func test_Combine_CurrentValueSubject_emits_values_to_an_observer() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
            return
        }

        // Given
        let subject = CurrentValueSubject<String, Error>("consequatur")
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
        XCTAssertEqual(emittedValues, ["consequatur", "dicta"])
    }

    func test_Combine_CurrentValueSubject_continuously_emits_values_to_an_observer() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
            return
        }

        // Given
        let subject = CurrentValueSubject<String, Error>("exercitationem")
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
        XCTAssertEqual(emittedValues, ["exercitationem", "dicta", "amet", "dolor"])
    }

    func test_Combine_CurrentValueSubject_emits_values_to_all_observers() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
            return
        }

        // Given
        let subject = CurrentValueSubject<String, Error>("provident")
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
        XCTAssertEqual(emittedValues, ["provident", "provident", "dicta", "dicta", "amet", "amet"])
    }

    func test_Combine_CurrentValueSubject_does_not_emit_values_to_cancelled_observers() throws {
        guard #available(iOS 13.0, *) else {
            try XCTSkipIf(true, "This test is for iOS 13.0+ only")
            return
        }

        // Given
        // "dicta" will be emitted because it is the initial value
        let subject = CurrentValueSubject<String, Error>("dicta")

        var emittedValues = [String]()
        let cancellable = subject.sink(receiveCompletion: { _ in
            // noop
        }) { value in
            emittedValues.append(value)
        }

        // When
        // Cancel the observer
        cancellable.cancel()

        // This will not be emitted anymore
        subject.send("amet")

        // Then
        XCTAssertEqual(emittedValues, ["dicta"])
    }
}
