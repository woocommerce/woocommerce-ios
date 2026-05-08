import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantSystemPromptTests {

    @Test
    func test_build_when_no_date_passed_then_embeds_today_with_weekday() {
        let prompt = AssistantSystemPrompt.build()
        let today = Self.todayISO()
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

    private static func todayISO() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
