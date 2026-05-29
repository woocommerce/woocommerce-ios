import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct WpComJetpackAIJWTProviderTests {

    @Test
    func test_currentJWT_when_cache_warm_and_not_expired_then_returns_cached_without_minting() async throws {
        // Given
        let blogID: Int64 = 12345
        let token = makeJWT(blogID: blogID, expiresIn: 3600)
        let counter = MintCounter()
        let provider = WpComJetpackAIJWTProvider(blogID: blogID, mint: counter.makeMint(token: token))
        _ = try await provider.currentJWT()

        // When
        let second = try await provider.currentJWT()

        // Then
        #expect(second == token)
        #expect(await counter.count == 1)
    }

    @Test
    func test_currentJWT_when_cached_token_expired_then_mints_fresh() async throws {
        // Given
        let blogID: Int64 = 12345
        let staleToken = makeJWT(blogID: blogID, expiresIn: -10)
        let freshToken = makeJWT(blogID: blogID, expiresIn: 3600)
        let counter = MintCounter(script: [staleToken, freshToken])
        let provider = WpComJetpackAIJWTProvider(blogID: blogID,
                                                 mint: counter.makeMintScript())
        _ = try await provider.currentJWT()

        // When
        let second = try await provider.currentJWT()

        // Then
        #expect(second == freshToken)
        #expect(await counter.count == 2)
    }

    @Test
    func test_currentJWT_when_cached_token_blog_id_mismatch_then_mints_fresh() async throws {
        // Given
        let expectedBlogID: Int64 = 12345
        let mismatchToken = makeJWT(blogID: 99999, expiresIn: 3600)
        let correctToken = makeJWT(blogID: expectedBlogID, expiresIn: 3600)
        let counter = MintCounter(script: [mismatchToken, correctToken])
        let provider = WpComJetpackAIJWTProvider(blogID: expectedBlogID,
                                                 mint: counter.makeMintScript())
        _ = try await provider.currentJWT()

        // When
        let second = try await provider.currentJWT()

        // Then
        #expect(second == correctToken)
        #expect(await counter.count == 2)
    }

    @Test
    func test_currentJWT_when_concurrent_callers_then_mints_exactly_once() async throws {
        // Given
        let blogID: Int64 = 12345
        let token = makeJWT(blogID: blogID, expiresIn: 3600)
        let counter = MintCounter()
        let provider = WpComJetpackAIJWTProvider(blogID: blogID, mint: counter.makeMint(token: token))

        // When
        await withTaskGroup(of: String?.self) { group in
            for _ in 0..<10 {
                group.addTask { try? await provider.currentJWT() }
            }
            for await _ in group {}
        }

        // Then
        #expect(await counter.count == 1)
    }

    @Test
    func test_currentJWT_when_token_within_clock_skew_margin_then_mints_fresh() async throws {
        // Given a token whose true `exp` is within the 60s clock-skew margin
        let blogID: Int64 = 12345
        let nearExpiry = makeJWT(blogID: blogID, expiresIn: 30)
        let fresh = makeJWT(blogID: blogID, expiresIn: 3600)
        let counter = MintCounter(script: [nearExpiry, fresh])
        let provider = WpComJetpackAIJWTProvider(blogID: blogID,
                                                 mint: counter.makeMintScript())
        _ = try await provider.currentJWT()

        // When
        let second = try await provider.currentJWT()

        // Then a fresh mint replaces the still-valid-on-the-clock token
        #expect(second == fresh)
        #expect(await counter.count == 2)
    }

    @Test
    func test_currentJWT_when_first_mint_throws_then_next_call_retries() async throws {
        // Given
        let blogID: Int64 = 12345
        let token = makeJWT(blogID: blogID, expiresIn: 3600)
        let mintBox = ThrowingMintFactory(failuresBeforeSuccess: 1, token: token)
        let provider = WpComJetpackAIJWTProvider(blogID: blogID, mint: mintBox.makeMint())

        // When / Then
        do {
            _ = try await provider.currentJWT()
            Issue.record("Expected the first mint to throw.")
        } catch {
            // expected
        }
        let recovered = try await provider.currentJWT()
        #expect(recovered == token)
        #expect(await mintBox.callCount == 2)
    }

    @Test
    func test_invalidate_when_called_then_next_currentJWT_mints_fresh() async throws {
        // Given
        let blogID: Int64 = 12345
        let firstToken = makeJWT(blogID: blogID, expiresIn: 3600)
        let secondToken = makeJWT(blogID: blogID, expiresIn: 3600)
        let counter = MintCounter(script: [firstToken, secondToken])
        let provider = WpComJetpackAIJWTProvider(blogID: blogID,
                                                 mint: counter.makeMintScript())
        _ = try await provider.currentJWT()

        // When
        await provider.invalidate()
        let second = try await provider.currentJWT()

        // Then
        #expect(second == secondToken)
        #expect(await counter.count == 2)
    }

    private func makeJWT(blogID: Int64, expiresIn seconds: Int) -> String {
        let header = #"{"alg":"HS256","typ":"JWT"}"#
        let exp = Int(Date().timeIntervalSince1970) + seconds
        let payload = "{\"blog_id\":\(blogID),\"exp\":\(exp)}"
        return [header, payload].map { Self.base64URLEncode(Data($0.utf8)) }.joined(separator: ".") + ".signature"
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private actor MintCounter {
    private(set) var count: Int = 0
    private var script: [String] = []

    init(script: [String] = []) {
        self.script = script
    }

    nonisolated func makeMint(token: String) -> WpComJetpackAIJWTProvider.Mint {
        { @Sendable _ in
            await self.recordCallAndReturn(token)
        }
    }

    nonisolated func makeMintScript() -> WpComJetpackAIJWTProvider.Mint {
        return { @Sendable _ in
            try await self.consumeNext()
        }
    }

    private func recordCallAndReturn(_ token: String) -> String {
        count += 1
        return token
    }

    private func consumeNext() throws -> String {
        count += 1
        guard !script.isEmpty else {
            throw AssistantError(kind: .auth, message: "mint script exhausted")
        }
        return script.removeFirst()
    }
}

private actor ThrowingMintFactory {
    private var failuresRemaining: Int
    private let token: String
    private(set) var callCount = 0

    init(failuresBeforeSuccess: Int, token: String) {
        self.failuresRemaining = failuresBeforeSuccess
        self.token = token
    }

    nonisolated func makeMint() -> WpComJetpackAIJWTProvider.Mint {
        { @Sendable _ in
            try await self.next()
        }
    }

    private func next() throws -> String {
        callCount += 1
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw AssistantError(kind: .auth, message: "scripted mint failure")
        }
        return token
    }
}
