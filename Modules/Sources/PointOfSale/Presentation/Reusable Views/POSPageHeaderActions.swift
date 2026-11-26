import SwiftUI

struct POSPageAction: Identifiable {
    let id: String
    let title: String
    let accessibilityHint: String
    let action: @MainActor () -> Void
}

struct POSPageActions {
    let primary: POSPageAction?
    let secondary: [POSPageAction]

    init(primary: POSPageAction?, secondary: [POSPageAction] = []) {
        self.primary = primary
        self.secondary = secondary
    }

    static let empty = POSPageActions(primary: nil)

    var allActions: [POSPageAction] {
        [primary].compactMap { $0 } + secondary
    }
}

struct POSPageHeaderActions: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posMetrics) private var metrics

    let actions: POSPageActions

    var body: some View {
        if horizontalSizeClass == .compact {
            menu(actions.allActions)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: metrics.spacing.medium) {
                    if let primary = actions.primary {
                        primaryButton(primary)
                    }
                    menu(actions.secondary)
                }

                menu(actions.allActions)
            }
        }
    }

    private func primaryButton(_ action: POSPageAction) -> some View {
        Button(action: action.action) {
            Text(action.title)
                .lineLimit(1)
        }
        .buttonStyle(POSFilledButtonStyle(size: .extraSmall))
        .accessibilityHint(action.accessibilityHint)
    }

    @ViewBuilder
    private func menu(_ menuActions: [POSPageAction]) -> some View {
        if menuActions.isNotEmpty {
            POSMenu {
                ForEach(menuActions) { action in
                    POSMenuButton(action.title, action: action.action)
                        .accessibilityHint(action.accessibilityHint)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.posBodyLargeBold)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .foregroundColor(.posOnSurface)
                    .padding(metrics.padding.small)
            }
            .accessibilityLabel(POSMenuAccessibility.moreActions)
        }
    }
}

#if DEBUG
#Preview("Two actions") {
    POSPageHeaderView(title: "Order #1821", trailingContent: {
        POSPageHeaderActions(actions: .init(primary: .init(id: "refund", title: "Issue refund", accessibilityHint: "", action: {}),
                                            secondary: [.init(id: "email", title: "Email receipt", accessibilityHint: "", action: {})]))
    })
}

#Preview("Single action") {
    POSPageHeaderView(title: "Order #1821", trailingContent: {
        POSPageHeaderActions(actions: .init(primary: .init(id: "email", title: "Email receipt", accessibilityHint: "", action: {})))
    })
}
#endif
