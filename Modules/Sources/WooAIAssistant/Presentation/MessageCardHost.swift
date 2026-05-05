import SwiftUI

struct MessageCardHost: View {

    let toolName: String
    let payload: AnyCodableJSON

    var body: some View {
        RawJSONCard(toolName: toolName, payload: payload)
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
