import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct ShowCardsTelemetryReducerTests {

    @Test
    func test_reduce_when_well_formed_payload_then_returns_aggregate_counts() {
        // Given
        let structured: AnyCodableJSON = .object([
            "requested": .int(4),
            "rendered": .int(2),
            "missing_refs": .array([.object(["reason": .string("not_found")]),
                                    .object(["reason": .string("not_found")])]),
            "rejected_refs": .array([.object(["reason": .string("duplicate")])])
        ])

        // When
        let counts = ShowCardsTelemetryReducer.reduce(structured)

        // Then
        #expect(counts == ShowCardsCounts(requestedCount: 4,
                                          renderedCount: 2,
                                          missingCount: 2,
                                          rejectedCount: 1))
    }

    @Test
    func test_reduce_when_empty_ref_arrays_then_returns_zero_counts_for_missing_and_rejected() {
        // Given
        let structured: AnyCodableJSON = .object([
            "requested": .int(1),
            "rendered": .int(1),
            "missing_refs": .array([]),
            "rejected_refs": .array([])
        ])

        // When
        let counts = ShowCardsTelemetryReducer.reduce(structured)

        // Then
        #expect(counts == ShowCardsCounts(requestedCount: 1,
                                          renderedCount: 1,
                                          missingCount: 0,
                                          rejectedCount: 0))
    }

    @Test
    func test_reduce_when_missing_refs_absent_then_treats_as_zero() {
        // Given
        let structured: AnyCodableJSON = .object([
            "requested": .int(2),
            "rendered": .int(2)
        ])

        // When
        let counts = ShowCardsTelemetryReducer.reduce(structured)

        // Then
        #expect(counts?.missingCount == 0)
        #expect(counts?.rejectedCount == 0)
    }

    @Test
    func test_reduce_when_requested_is_non_numeric_then_returns_nil() {
        // Given
        let structured: AnyCodableJSON = .object([
            "requested": .string("oops"),
            "rendered": .int(0)
        ])

        // When
        let counts = ShowCardsTelemetryReducer.reduce(structured)

        // Then
        #expect(counts == nil)
    }

    @Test
    func test_reduce_when_payload_is_not_an_object_then_returns_nil() {
        // Given
        let structured: AnyCodableJSON = .array([.int(1)])

        // When
        let counts = ShowCardsTelemetryReducer.reduce(structured)

        // Then
        #expect(counts == nil)
    }
}
