import SwiftUI

struct EntityCard<Payload, Row: View>: View {

    let title: String
    let iconSystemName: String
    let payloads: [Payload]
    let isEmpty: (Payload) -> Bool
    let row: (Payload, _ showDivider: Bool) -> Row

    var body: some View {
        let visible = visibleRows
        if visible.isEmpty {
            EmptyView()
        } else {
            AssistantDashboardCardShell(
                title: title,
                iconSystemName: iconSystemName,
                bodyContent: {
                    VStack(spacing: 0) {
                        ForEach(visible.indices, id: \.self) { index in
                            row(visible[index], index < visible.count - 1)
                        }
                    }
                }
            )
        }
    }

    var visibleRows: [Payload] {
        EntityCard.visibleRows(payloads, isEmpty: isEmpty)
    }

    static func visibleRows(_ payloads: [Payload], isEmpty: (Payload) -> Bool) -> [Payload] {
        let nonEmpty = payloads.filter { !isEmpty($0) }
        return Array(nonEmpty.prefix(entityCardVisibleRowLimit))
    }
}
