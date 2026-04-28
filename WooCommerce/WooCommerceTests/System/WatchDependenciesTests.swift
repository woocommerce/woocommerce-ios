import XCTest
@testable import Networking
@testable import WooCommerce
import class WooFoundationCore.CurrencySettings

final class WatchDependenciesTests: XCTestCase {

    func test_decode_defaults_jetpack_visitor_stats_support_to_false_for_legacy_payloads() throws {
        // Given
        let dependencies = makeDependencies(supportsJetpackVisitorStats: true)
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: try JSONEncoder().encode(dependencies)) as? [String: Any])
        payload.removeValue(forKey: "supportsJetpackVisitorStats")
        let legacyData = try JSONSerialization.data(withJSONObject: payload)

        // When
        let decoded = try JSONDecoder().decode(WatchDependencies.self, from: legacyData)

        // Then
        XCTAssertFalse(decoded.supportsJetpackVisitorStats)
    }

    func test_encode_and_decode_roundtrip_preserves_jetpack_visitor_stats_support() throws {
        // Given
        let dependencies = makeDependencies(supportsJetpackVisitorStats: true)

        // When
        let data = try JSONEncoder().encode(dependencies)
        let decoded = try JSONDecoder().decode(WatchDependencies.self, from: data)

        // Then
        XCTAssertEqual(decoded, dependencies)
        XCTAssertTrue(decoded.supportsJetpackVisitorStats)
    }
}

private extension WatchDependenciesTests {

    func makeDependencies(supportsJetpackVisitorStats: Bool) -> WatchDependencies {
        WatchDependencies(storeID: 123,
                          storeName: "Jetpack Demo",
                          currencySettings: CurrencySettings(),
                          credentials: .init(authToken: "token"),
                          supportsJetpackVisitorStats: supportsJetpackVisitorStats,
                          applicationPassword: nil,
                          enablesCrashReports: true,
                          account: nil)
    }
}
