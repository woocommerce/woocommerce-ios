import SwiftUI

struct POSPageAction: Identifiable {
    let id: String
    let title: String
    let accessibilityHint: String?
    let action: @MainActor () -> Void

    init(id: String, title: String, accessibilityHint: String? = nil, action: @escaping @MainActor () -> Void) {
        self.id = id
        self.title = title
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
}

struct POSPageActions {
    enum CompactLayout {
        case none
        case stacked(primary: POSPageAction?, secondary: [POSPageAction])
        case overflow(primary: POSPageAction?, menu: [POSPageAction])
    }

    let primary: POSPageAction?
    let secondary: [POSPageAction]

    init(primary: POSPageAction?, secondary: [POSPageAction] = []) {
        self.primary = primary
        self.secondary = secondary
    }

    static let none = POSPageActions(primary: nil)

    var compactLayout: CompactLayout {
        let count = (primary == nil ? 0 : 1) + secondary.count
        switch count {
        case 0:
            return .none
        case ...Constants.maxStackedCompactActions:
            return .stacked(primary: primary, secondary: secondary)
        default:
            return .overflow(primary: primary, menu: secondary)
        }
    }

    private enum Constants {
        static let maxStackedCompactActions = 2
    }
}

struct POSPage<HeaderBottomContent: View, Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posHeaderBackButtonPadding) private var backButtonPadding
    @Environment(\.posMetrics) private var metrics

    private let title: String
    private let compactBackAction: (() -> Void)?
    private let actions: POSPageActions
    private let headerBottomContent: HeaderBottomContent
    private let content: Content

    init(title: String,
         compactBackAction: (() -> Void)? = nil,
         actions: POSPageActions = .none,
         @ViewBuilder headerBottomContent: () -> HeaderBottomContent = { EmptyView() },
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.compactBackAction = compactBackAction
        self.actions = actions
        self.headerBottomContent = headerBottomContent()
        self.content = content()
    }

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            POSPageHeaderView(
                title: title,
                backButtonConfiguration: backButtonConfiguration,
                trailingContent: {
                    if !isCompact {
                        POSPageHeaderActionsView(actions: actions)
                    }
                },
                bottomContent: {
                    headerBottomContent
                }
            )
            .posHeaderBackButtonPadding(isCompact ? backButtonPadding : metrics.padding.none)
            .fixedSize(horizontal: false, vertical: true)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            content
                .frame(maxHeight: .infinity, alignment: .top)

            if isCompact {
                POSPageCompactActionsBar(layout: actions.compactLayout)
            }
        }
    }

    private var backButtonConfiguration: POSPageHeaderBackButtonConfiguration? {
        guard isCompact, let compactBackAction else {
            return nil
        }
        return .init(state: .enabled, action: compactBackAction)
    }
}

private struct POSPageHeaderActionsView: View {
    let actions: POSPageActions

    var body: some View {
        if let primary = actions.primary {
            Button(action: primary.action) {
                Text(primary.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .buttonStyle(POSFilledButtonStyle(size: .extraSmall))
            .posPageActionAccessibilityHint(primary.accessibilityHint)
        }

        if !actions.secondary.isEmpty {
            POSPageActionsMenu(actions: actions.secondary)
        }
    }
}

private struct POSPageCompactActionsBar: View {
    @Environment(\.posMetrics) private var metrics
    let layout: POSPageActions.CompactLayout

    var body: some View {
        switch layout {
        case .none:
            EmptyView()
        case .stacked(let primary, let secondary):
            VStack(spacing: metrics.spacing.medium) {
                if let primary {
                    button(for: primary, isPrimary: true)
                }
                ForEach(secondary) { action in
                    button(for: action, isPrimary: false)
                }
            }
            .posPhoneBottomButtonPadding()
        case .overflow(let primary, let menu):
            HStack(spacing: metrics.spacing.medium) {
                if let primary {
                    button(for: primary, isPrimary: true)
                } else {
                    Spacer(minLength: metrics.spacing.none)
                }
                POSPageActionsMenu(actions: menu)
            }
            .posPhoneBottomButtonPadding()
        }
    }

    @ViewBuilder
    private func button(for action: POSPageAction, isPrimary: Bool) -> some View {
        let button = Button(action.title, action: action.action)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .posPageActionAccessibilityHint(action.accessibilityHint)
        if isPrimary {
            button.buttonStyle(POSFilledButtonStyle(size: .normal))
        } else {
            button.buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
    }
}

private struct POSPageActionsMenu: View {
    @Environment(\.posMetrics) private var metrics
    let actions: [POSPageAction]

    var body: some View {
        POSMenu {
            ForEach(actions) { action in
                POSMenuButton(action.title, action: action.action)
                    .posPageActionAccessibilityHint(action.accessibilityHint)
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

private extension View {
    @ViewBuilder
    func posPageActionAccessibilityHint(_ hint: String?) -> some View {
        if let hint {
            accessibilityHint(hint)
        } else {
            self
        }
    }
}

#if DEBUG
#Preview("Two actions") {
    POSPage(
        title: "#1821",
        compactBackAction: {},
        actions: .init(primary: .init(id: "refund", title: "Issue refund", action: {}),
                       secondary: [.init(id: "email", title: "Email receipt", action: {})])
    ) {
        Color.posSurface
    }
}

#Preview("Overflow") {
    POSPage(
        title: "#1821",
        compactBackAction: {},
        actions: .init(primary: .init(id: "refund", title: "Issue refund", action: {}),
                       secondary: [.init(id: "email", title: "Email receipt", action: {}),
                                   .init(id: "print", title: "Print receipt", action: {})])
    ) {
        Color.posSurface
    }
}
#endif
