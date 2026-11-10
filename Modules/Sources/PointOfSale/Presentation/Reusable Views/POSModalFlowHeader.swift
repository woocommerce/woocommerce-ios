import SwiftUI

/// Header of a full-screen POS modal flow on phone. The close button sits where the back button sits on other POS pages.
struct POSModalFlowHeader: View {
    @Environment(\.posMetrics) private var metrics
    let title: String
    let closeAction: POSModalFlowCloseAction?

    var body: some View {
        POSRefundNavigationHeader(title: title,
                                  backAction: closeAction.map { closeAction in { closeAction.action() } },
                                  backAccessibilityLabel: closeAction?.accessibilityLabel ?? "",
                                  backAccessibilityIdentifier: closeAction?.accessibilityIdentifier)
        .posHeaderBackButtonIcon(systemName: "xmark")
        // A step without a close button keeps its space, so the title does not move between steps.
        .padding(.leading, closeAction == nil ? POSHeaderLayoutConstants.compactBackButtonSize + metrics.spacing.medium : metrics.spacing.none)
    }
}

extension View {
    /// Shows `content` as a full-screen POS flow on phone: a header with `title` and the close button that the content
    /// sets with `posModalCloseButton`. A `nil` title leaves the view unchanged.
    ///
    /// `posModal` applies it for `.fullScreen(title:)`. Apply it directly only inside a presentation that is not a
    /// `posModal`, such as a full-screen cover.
    func posFullScreenFlowHeader(title: String?) -> some View {
        modifier(POSFullScreenFlowHeaderModifier(title: title))
    }
}

private struct POSFullScreenFlowHeaderModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    let title: String?
    @State private var closeAction: POSModalFlowCloseAction?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let title {
            content
                .environment(\.posModalCompactStyle, .fullScreen(title: title))
                .onPreferenceChange(POSModalFlowCloseActionKey.self) { closeAction = $0 }
                .safeAreaInset(edge: .top, spacing: metrics.spacing.none) {
                    POSModalFlowHeader(title: title, closeAction: closeAction)
                }
        } else {
            content
        }
    }
}

extension View {
    /// Offers `action` as the close button of the full-screen flow header, without adding a close button to the content.
    /// Use it for content that lays itself out, such as a scrolling list; `posModalCloseButton` also centers the content.
    func posModalFlowCloseAction(enabled: Bool,
                                 accessibilityLabel: String,
                                 accessibilityIdentifier: String? = nil,
                                 action: @escaping () -> Void) -> some View {
        modifier(POSModalFlowCloseActionModifier(enabled: enabled,
                                                 accessibilityLabel: accessibilityLabel,
                                                 accessibilityIdentifier: accessibilityIdentifier,
                                                 action: action))
    }
}

private struct POSModalFlowCloseActionModifier: ViewModifier {
    let enabled: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String?
    let action: () -> Void
    @State private var flowCloseAction = POSModalFlowCloseAction()

    func body(content: Content) -> some View {
        content
            .preference(key: POSModalFlowCloseActionKey.self, value: enabled ? updatedFlowCloseAction : nil)
    }

    private var updatedFlowCloseAction: POSModalFlowCloseAction {
        flowCloseAction.action = action
        flowCloseAction.accessibilityLabel = accessibilityLabel
        flowCloseAction.accessibilityIdentifier = accessibilityIdentifier
        return flowCloseAction
    }
}

/// The close action that a modal's content offers to `POSModalFlowHeader`, set by `posModalCloseButton`.
///
/// It is a reference type so the header always calls the content's latest action, while the preference value only
/// changes when the content itself changes.
final class POSModalFlowCloseAction: Equatable {
    var action: () -> Void = {}
    var accessibilityLabel: String = ""
    var accessibilityIdentifier: String?

    static func == (lhs: POSModalFlowCloseAction, rhs: POSModalFlowCloseAction) -> Bool {
        lhs === rhs
    }
}

struct POSModalFlowCloseActionKey: PreferenceKey {
    static let defaultValue: POSModalFlowCloseAction? = nil

    static func reduce(value: inout POSModalFlowCloseAction?, nextValue: () -> POSModalFlowCloseAction?) {
        value = value ?? nextValue()
    }
}
