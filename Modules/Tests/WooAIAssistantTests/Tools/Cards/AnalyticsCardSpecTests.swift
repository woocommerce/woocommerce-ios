import Foundation
import Testing
@testable import WooAIAssistant

struct AnalyticsCardSpecTests {
    @Test
    func test_encoded_when_interval_and_currency_missing_then_emits_day_and_currency_none_sentinel() {
        // Given
        let spec = AnalyticsCardSpec(kind: .orders,
                                     after: "2026-04-01",
                                     before: "2026-04-30",
                                     interval: nil,
                                     currency: nil)

        // When
        let encoded = spec.encoded

        // Then
        #expect(encoded == "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:currency:none")
    }

    @Test
    func test_encoded_when_all_fields_present_then_appends_segments_in_order() {
        // Given
        let spec = AnalyticsCardSpec(kind: .orders,
                                     after: "2026-04-01",
                                     before: "2026-04-30",
                                     interval: "week",
                                     currency: "USD")

        // When
        let encoded = spec.encoded

        // Then
        #expect(encoded == "analytics_orders:after:2026-04-01:before:2026-04-30:interval:week:currency:USD")
    }

    @Test
    func test_decode_round_trips_for_interval_and_currency_combinations() {
        // Given
        let cases: [AnalyticsCardSpec] = [
            AnalyticsCardSpec(kind: .orders, after: "2026-04-01", before: "2026-04-30",
                              interval: "day", currency: nil),
            AnalyticsCardSpec(kind: .orders, after: "2026-01-01", before: "2026-12-31",
                              interval: "month", currency: nil),
            AnalyticsCardSpec(kind: .orders, after: "2026-05-01", before: "2026-05-07",
                              interval: "day", currency: "EUR"),
            AnalyticsCardSpec(kind: .orders, after: "2026-05-01", before: "2026-05-07",
                              interval: "week", currency: "GBP")
        ]

        // When / Then
        for spec in cases {
            let decoded = AnalyticsCardSpec.decode(spec.encoded)
            #expect(decoded == spec, "round-trip failed for \(spec.encoded)")
        }
    }

    @Test
    func test_decode_when_currency_is_none_sentinel_then_returns_nil_currency() {
        // Given
        let id = "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:currency:none"

        // When
        let decoded = AnalyticsCardSpec.decode(id)

        // Then
        #expect(decoded?.currency == nil)
        #expect(decoded?.kind == .orders)
    }

    @Test
    func test_decode_when_prefix_missing_then_returns_nil() {
        // Given / When
        let decoded = AnalyticsCardSpec.decode("revenue:after:2026-04-01:before:2026-04-30:interval:day:currency:none")

        // Then
        #expect(decoded == nil)
    }

    @Test
    func test_decode_when_kind_unknown_then_returns_nil() {
        // Given / When
        let decoded = AnalyticsCardSpec.decode("analytics_profit:after:2026-04-01:before:2026-04-30:interval:day:currency:none")

        // Then
        #expect(decoded == nil)
    }

    @Test
    func test_decode_when_required_after_or_before_missing_then_returns_nil() {
        // Given / When
        let missingBefore = AnalyticsCardSpec.decode("analytics_orders:after:2026-04-01:interval:day:currency:none")
        let missingAfter = AnalyticsCardSpec.decode("analytics_orders:before:2026-04-30:interval:day:currency:none")

        // Then
        #expect(missingBefore == nil)
        #expect(missingAfter == nil)
    }

    @Test
    func test_decode_when_dates_are_malformed_then_returns_nil() {
        // Given / When
        let decoded = AnalyticsCardSpec.decode(
            "analytics_orders:after:04-01-2026:before:04-30-2026:interval:day:currency:none"
        )

        // Then
        #expect(decoded == nil)
    }

    @Test
    func test_decode_when_interval_not_in_allowed_set_then_returns_nil() {
        // Given / When
        let decoded = AnalyticsCardSpec.decode(
            "analytics_orders:after:2026-04-01:before:2026-04-30:interval:fortnight:currency:none"
        )

        // Then
        #expect(decoded == nil)
    }

    @Test
    func test_decode_when_currency_is_not_three_uppercase_letters_then_returns_nil() {
        // Given / When
        let lowercase = AnalyticsCardSpec.decode(
            "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:currency:usd"
        )
        let tooShort = AnalyticsCardSpec.decode(
            "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:currency:US"
        )

        // Then
        #expect(lowercase == nil)
        #expect(tooShort == nil)
    }

    @Test
    func test_decode_when_unknown_segment_present_then_returns_nil() {
        // Given / When
        let decoded = AnalyticsCardSpec.decode(
            "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:granularity:fine:currency:none"
        )

        // Then
        #expect(decoded == nil)
    }

    @Test
    func test_decode_when_interval_or_currency_missing_then_returns_nil() {
        // Given / When
        let missingInterval = AnalyticsCardSpec.decode(
            "analytics_orders:after:2026-04-01:before:2026-04-30:currency:none"
        )
        let missingCurrency = AnalyticsCardSpec.decode(
            "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day"
        )

        // Then
        #expect(missingInterval == nil)
        #expect(missingCurrency == nil)
    }
}
