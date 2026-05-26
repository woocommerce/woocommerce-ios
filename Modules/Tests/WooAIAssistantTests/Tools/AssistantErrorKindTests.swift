import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantErrorKindTests {
    @Test
    func test_assistantErrorKind_when_decoded_from_snake_case_then_matches_enum_case() throws {
        // Given
        let raws = ["network", "auth", "rate_limit", "timeout", "upstream_failure",
                    "tool_failed", "invalid_tool_call", "outcome_unknown", "cancelled", "unknown"]
        let json = try JSONEncoder().encode(raws)

        // When
        let decoded = try JSONDecoder().decode([AssistantErrorKind].self, from: json)

        // Then
        #expect(decoded == [
            .network,
            .auth,
            .rateLimit,
            .timeout,
            .upstreamFailure,
            .toolFailed,
            .invalidToolCall,
            .outcomeUnknown,
            .cancelled,
            .unknown
        ])
    }

    @Test
    func test_assistantErrorKind_when_encoded_then_emits_snake_case_strings() throws {
        // Given
        let cases: [AssistantErrorKind] = [.rateLimit, .upstreamFailure, .invalidToolCall, .outcomeUnknown]

        // When
        let data = try JSONEncoder().encode(cases)
        let stringified = try #require(String(data: data, encoding: .utf8))

        // Then
        #expect(stringified == #"["rate_limit","upstream_failure","invalid_tool_call","outcome_unknown"]"#)
    }

    @Test
    func test_assistantErrorKind_when_outcomeUnknown_then_distinct_from_unknown() {
        #expect(AssistantErrorKind.outcomeUnknown != AssistantErrorKind.unknown)
        #expect(AssistantErrorKind.outcomeUnknown.rawValue == "outcome_unknown")
        #expect(AssistantErrorKind.unknown.rawValue == "unknown")
    }
}
