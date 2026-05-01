#if DEBUG
import Foundation
import SwiftUI

/// Single source of truth for preview/snapshot states across components.
enum AssistantChatScenario: String, CaseIterable {
    case empty
    case singleUserMessage
    case assistantTyping
    case assistantStreamingText
    case textPlusCard
    case toolActivityPill
    case pendingConfirmation
    case pendingConfirmationBulk
    case failedMidStream
    case outcomeUnknown
    case iterationCap
    case multiTurn

    var displayName: String {
        switch self {
        case .empty: return "Empty"
        case .singleUserMessage: return "Single user message"
        case .assistantTyping: return "Assistant typing"
        case .assistantStreamingText: return "Assistant streaming text"
        case .textPlusCard: return "Text + card"
        case .toolActivityPill: return "Tool activity pill"
        case .pendingConfirmation: return "Pending confirmation"
        case .pendingConfirmationBulk: return "Pending confirmation (bulk)"
        case .failedMidStream: return "Failed mid-stream"
        case .outcomeUnknown: return "Outcome unknown"
        case .iterationCap: return "Iteration cap"
        case .multiTurn: return "Multi-turn"
        }
    }
}

@MainActor
struct AssistantChatScenarioBuilder {

    let scenario: AssistantChatScenario

    func build() -> Configuration {
        switch scenario {
        case .empty:
            return Configuration(controller: MockAssistantController.make())

        case .singleUserMessage:
            let messages = [MockAssistantController.userMessage("How many orders today?")]
            return Configuration(controller: MockAssistantController.make(messages: messages))

        case .assistantTyping:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("How many orders today?"),
                ChatMessage(role: .assistant, segments: [], isStreaming: true)
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages,
                                                                          streaming: .sending))

        case .assistantStreamingText:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Summarise yesterday in one line"),
                MockAssistantController.assistantText(
                    "Yesterday you took 12 orders for a total of $1,284 across",
                    streaming: true
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages,
                                                                          streaming: .streaming))

        case .textPlusCard:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Show me the last two orders"),
                MockAssistantController.assistantWithCard(
                    text: "Here are the last two orders.",
                    toolName: "orders_list",
                    payload: MockAssistantController.sampleOrderListPayload()
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages))

        case .toolActivityPill:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Find Sarah's orders"),
                MockAssistantController.assistantWithToolPill(
                    text: "",
                    tool: "customers_search",
                    status: .running,
                    streaming: true
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages,
                                                                          streaming: .streaming))

        case .pendingConfirmation:
            let proposalID = UUID()
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Mark order 3479 as completed"),
                MockAssistantController.assistantConfirmation(
                    text: "I'll mark order #3479 as completed.",
                    proposalID: proposalID,
                    tool: "orders_update",
                    preview: "Update order #3479: status processing -> completed",
                    status: .pending
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages,
                                                                          streaming: .idle))

        case .pendingConfirmationBulk:
            let proposalID = UUID()
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Move all 12 processing orders to completed"),
                MockAssistantController.assistantConfirmation(
                    text: "I'll move 12 orders from processing to completed.",
                    proposalID: proposalID,
                    tool: "orders_bulk_update",
                    preview: "Update 12 orders: status -> completed (emails customers)",
                    status: .pending
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages,
                                                                          streaming: .idle))

        case .failedMidStream:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Refund order 3470"),
                MockAssistantController.assistantText("Looking that up", streaming: false)
            ]
            return Configuration(controller: MockAssistantController.make(
                messages: messages,
                streaming: .failed("Network is unreachable. Try again in a moment.")
            ))

        case .outcomeUnknown:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Update product 64 price to $19.99"),
                MockAssistantController.assistantText(
                    "Submitting the price update now.",
                    streaming: false
                )
            ]
            return Configuration(controller: MockAssistantController.make(
                messages: messages,
                streaming: .outcomeUnknown("The connection dropped before we got a confirmation. Verify the price before retrying.")
            ))

        case .iterationCap:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Compare every order this month"),
                MockAssistantController.assistantText(
                    "I've gathered most of the data but had to stop short of finishing the comparison.",
                    streaming: false
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages),
                                 showIterationCapBanner: true)

        case .multiTurn:
            let messages: [ChatMessage] = [
                MockAssistantController.userMessage("Top product yesterday?"),
                MockAssistantController.assistantText("Top product yesterday was the Striped Beanie with 14 units sold."),
                MockAssistantController.userMessage("And revenue?"),
                MockAssistantController.assistantText("Striped Beanie generated $293.86 in revenue."),
                MockAssistantController.userMessage("Show me the orders"),
                MockAssistantController.assistantWithCard(
                    text: "Here are the matching orders.",
                    toolName: "orders_list",
                    payload: MockAssistantController.sampleOrderListPayload()
                )
            ]
            return Configuration(controller: MockAssistantController.make(messages: messages))
        }
    }

    struct Configuration {
        let controller: AssistantController
        var showIterationCapBanner: Bool = false
    }
}
#endif
