import SwiftUI

struct MessageCardHost: View {

    let toolName: String
    let payload: AnyCodableJSON

    var body: some View {
        if let typed = ResultCardRegistry.shared.card(for: toolName, payload: payload) {
            typed
        } else {
            RawJSONCard(toolName: toolName, payload: payload)
        }
    }
}

/// Hook for typed card renderers. Returns nil today so all results render as
/// raw JSON; keeping the registry stub now avoids churning MessageCardHost
/// when the typed renderers (orders, products, customers) ship.
struct ResultCardRegistry {

    static let shared = ResultCardRegistry()

    func card(for toolName: String, payload: AnyCodableJSON) -> AnyView? {
        nil
    }
}

#if DEBUG
#Preview("Fallback to JSON") {
    MessageCardHost(toolName: "orders_list",
                    payload: MockAssistantController.sampleOrderListPayload())
        .padding()
}

#Preview("In chat") {
    AssistantChatView.preview(.textPlusCard)
}
#endif
