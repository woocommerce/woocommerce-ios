import Foundation
import Testing
@testable import WooAIAssistant

struct AssistantSystemPromptTests {

    @Test
    func test_build_when_no_date_passed_then_embeds_today_with_weekday() {
        let prompt = AssistantSystemPrompt.build()
        let today = todayISO()
        #expect(prompt.contains("Today is \(today) ("))
    }

    @Test
    func test_build_when_frozen_date_passed_then_embeds_that_date_with_weekday() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")
        #expect(prompt.contains("Today is 2026-04-27 (Monday)"))
    }

    @Test
    func test_build_when_unparseable_date_passed_then_falls_back_to_raw_string() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "not-a-date")
        #expect(prompt.contains("Today is not-a-date."))
    }

    @Test
    func test_build_documents_analytics_cards_without_prose_only_exception() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")
        let analyticsPattern = section(in: prompt, from: "Pattern 6 - Analytics breakdowns.", to: "Pattern 7 - Refusing")
        let directProseLines = prompt.split(separator: "\n").filter {
            $0.contains("answer plainly in prose") || $0.contains("answer directly in prose")
        }

        #expect(analyticsPattern.contains("call `show_cards` to render the matching analytics card"))
        #expect(analyticsPattern.contains("grouping grain with a date window"))
        #expect(analyticsPattern.contains("Do not turn a monthly window into interval=month"))
        #expect(directProseLines.allSatisfy { !$0.localizedCaseInsensitiveContains("analytics") })
    }

    @Test
    func test_build_documents_top_products_as_product_cards() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")

        #expect(prompt.contains("Top / best-selling products are product-entity answers"))
        #expect(prompt.contains("popularity sorting"))
        #expect(prompt.contains("render product cards"))
        #expect(prompt.contains("The UI never renders cards on its own"))
        #expect(prompt.contains("Use `show_cards` in the same assistant response as your prose"))
    }

    @Test
    func test_build_documents_stock_queries_as_product_level_show_cards() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")

        #expect(prompt.contains("Broad stock questions are product-level answers"))
        #expect(prompt.contains("Do not inspect variations unless the merchant explicitly asks"))
        #expect(prompt.contains("`show_cards` fetches and renders product"))
    }

    @Test
    func test_build_documents_singular_latest_mixed_entities_as_cards() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")

        #expect(prompt.contains("Singular latest/last entity requests are card-backed entity answers too"))
        #expect(prompt.contains("fetch one latest row"))
        #expect(prompt.contains("When one turn asks for entities from multiple families"))
        #expect(prompt.contains("one `show_cards` call"))
        #expect(prompt.contains("Don't replace mixed entity cards with prose"))
    }

    @Test
    func test_build_directs_show_cards_after_every_successful_write() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")
        let writePattern = section(in: prompt, from: "Pattern 4 - Write tool", to: "Writes are schema-bound")

        // Pattern 4 must explicitly tell the model to render the updated entity after writes.
        #expect(writePattern.contains("After the write succeeds, call `show_cards` with that entity's id"))
        // The information-vs-writes section reinforces the same directive.
        #expect(prompt.contains("After every successful write, call `show_cards` with the updated"))
        // The Rules summary keeps the directive top-of-prompt-summary.
        #expect(prompt.contains("After a successful write, always call `show_cards`"))
    }

    @Test
    func test_build_keeps_remote_tool_names_out_of_prompt() {
        let prompt = AssistantSystemPrompt.build(todayISODate: "2026-04-27")
        let remoteToolNames = [
            "orders_list",
            "orders_get",
            "products_list",
            "products_get",
            "analytics_revenue",
            "analytics_orders",
            "analytics_stats",
            "orders_bulk_update",
            "products_bulk_update",
            "product_variations_bulk_update"
        ]

        #expect(prompt.contains("`show_cards`"))
        #expect(remoteToolNames.allSatisfy { !prompt.contains($0) })
    }

    private func section(in text: String, from startMarker: String, to endMarker: String) -> Substring {
        guard let start = text.range(of: startMarker)?.lowerBound,
              let end = text.range(of: endMarker, range: start..<text.endIndex)?.lowerBound else {
            Issue.record("Expected prompt section markers")
            return ""
        }
        return text[start..<end]
    }

    private func todayISO() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
