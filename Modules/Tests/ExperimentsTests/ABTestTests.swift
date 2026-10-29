import AutomatticTracks
import Foundation
import Testing
@testable import Experiments

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct ABTestTests {
    @Test func test_start_when_ExPlat_refresh_completes_on_a_background_queue_then_it_returns() async throws {
        // Given
        try #require(ABTest.genuineCases.contains { $0.context == .loggedIn }, "The test needs a genuine logged-in experiment.")
        let previousExPlat = ExPlat.shared
        URLProtocol.registerClass(MockExPlatURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(MockExPlatURLProtocol.self)
            ExPlat.shared = previousExPlat
        }
        ExPlat.configure(platform: "woocommerceios", oAuthToken: nil, userAgent: nil, anonId: nil)

        // When
        await ABTest.start(for: .loggedIn)

        // Then
        var requests = MockExPlatURLProtocol.requests.stream.makeAsyncIterator()
        #expect(await requests.next() != nil)
    }
}
