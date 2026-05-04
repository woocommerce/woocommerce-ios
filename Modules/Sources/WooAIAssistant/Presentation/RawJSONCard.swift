import SwiftUI
import CocoaLumberjackSwift

struct RawJSONCard: View {

    let toolName: String
    let payload: AnyCodableJSON

    @State private var isExpanded = false

    private static let collapsedLines = 3

    var body: some View {
        CardShell(label: toolName, trailingChevron: false) {
            VStack(alignment: .leading, spacing: AssistantSpacing.small) {
                Text(prettyJSON)
                    .font(.assistantMonospaced)
                    .foregroundStyle(Color.primary)
                    .lineLimit(isExpanded ? nil : Self.collapsedLines)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if shouldOfferExpand {
                    Button {
                        withAnimation(.smooth(duration: AssistantMotion.snap)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? Localization.showLess : Localization.showAll)
                            .font(.assistantCaption)
                            .foregroundStyle(Color(.accent))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var prettyJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(payload)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            DDLogError("RawJSONCard pretty-print failed: \(error)")
            return ""
        }
    }

    private var shouldOfferExpand: Bool {
        prettyJSON.split(separator: "\n").count > Self.collapsedLines
    }

    private enum Localization {
        static let showAll = NSLocalizedString(
            "assistant.card.raw.showAll",
            value: "Show all",
            comment: "Toggle to expand a collapsed JSON block in the AI Assistant raw card"
        )
        static let showLess = NSLocalizedString(
            "assistant.card.raw.showLess",
            value: "Show less",
            comment: "Toggle to collapse an expanded JSON block in the AI Assistant raw card"
        )
    }
}

#if DEBUG
#Preview("Short") {
    RawJSONCard(toolName: "orders_list",
                payload: MockAssistantController.sampleOrderListPayload())
        .padding()
}

#Preview("In chat") {
    AssistantChatView.preview(.textPlusCard)
}
#endif
