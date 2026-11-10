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
