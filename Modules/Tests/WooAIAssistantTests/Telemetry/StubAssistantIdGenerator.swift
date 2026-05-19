import Foundation
@testable import WooAIAssistant

@MainActor
final class StubAssistantIdGenerator: AssistantIdGenerator {

    private var values: [String]
    private(set) var requests: Int = 0

    init(_ values: [String]) {
        self.values = values
    }

    nonisolated func nextID() -> String {
        MainActor.assumeIsolated {
            requests += 1
            if values.isEmpty {
                return UUID().uuidString
            }
            return values.removeFirst()
        }
    }
}
