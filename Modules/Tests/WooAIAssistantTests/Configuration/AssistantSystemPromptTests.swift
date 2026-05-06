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

        #expect(analyticsPattern.contains("show_cards"))
        #expect(analyticsPattern.contains("analytics_stats"))
        #expect(analyticsPattern.contains("currency:none"))
        #expect(directProseLines.allSatisfy { !$0.localizedCaseInsensitiveContains("analytics") })
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
