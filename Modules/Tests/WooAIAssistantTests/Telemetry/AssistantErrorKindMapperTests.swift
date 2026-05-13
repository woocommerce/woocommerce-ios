import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantErrorKindMapperTests {

    @Test
    func test_map_when_network_kind_then_returns_network() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .network, message: "boom"))

        // Then
        #expect(result == .network)
    }

    @Test
    func test_map_when_auth_kind_then_returns_auth() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .auth, message: "denied"))

        // Then
        #expect(result == .auth)
    }

    @Test
    func test_map_when_rateLimit_kind_then_returns_rateLimited() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .rateLimit, message: "slow down"))

        // Then
        #expect(result == .rateLimited)
    }

    @Test
    func test_map_when_timeout_kind_then_returns_timeout() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .timeout, message: "took too long"))

        // Then
        #expect(result == .timeout)
    }

    @Test
    func test_map_when_upstreamFailure_kind_then_returns_serverError() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .upstreamFailure, message: "upstream"))

        // Then
        #expect(result == .serverError)
    }

    @Test
    func test_map_when_invalidToolCall_kind_then_returns_validationError() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .invalidToolCall, message: "bad args"))

        // Then
        #expect(result == .validationError)
    }

    @Test
    func test_map_when_cancelled_kind_then_returns_cancelled() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .cancelled, message: "user cancelled"))

        // Then
        #expect(result == .cancelled)
    }

    @Test
    func test_map_when_unknown_kind_and_no_code_then_returns_unknown() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .unknown, message: "no idea"))

        // Then
        #expect(result == .unknown)
    }

    @Test
    func test_map_when_unknown_kind_with_auth_http_code_then_uses_code_fallback() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .unknown, code: "403", message: "forbidden"))

        // Then
        #expect(result == .auth)
    }

    @Test
    func test_map_when_unknown_kind_with_server_http_code_then_returns_serverError() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .unknown, code: "503", message: "down"))

        // Then
        #expect(result == .serverError)
    }

    @Test
    func test_map_when_unknown_kind_with_rate_limited_code_then_returns_rateLimited() {
        // When
        let result = AssistantErrorKindMapper.map(AssistantError(kind: .unknown, code: "429", message: "slow"))

        // Then
        #expect(result == .rateLimited)
    }

    @Test
    func test_mapCancellation_when_called_then_returns_cancelled() {
        // When
        let result = AssistantErrorKindMapper.mapCancellation()

        // Then
        #expect(result == .cancelled)
    }
}
