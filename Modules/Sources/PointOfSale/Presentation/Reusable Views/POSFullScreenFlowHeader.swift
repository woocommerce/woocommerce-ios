import SwiftUI

extension View {
    /// The header X shows exactly when the modal can be dismissed by a tap outside on iPad, and runs the same dismissal.
    func posFullScreenFlowHeader(style: POSModalCompactStyle?, dismissAction: (() -> Void)?) -> some View {
        modifier(POSFullScreenFlowHeaderModifier(style: style, dismissAction: dismissAction))
    }

    func posModalFlowBackAction(enabled: Bool,
                                actionEnabled: Bool = true,
                                accessibilityIdentifier: String? = nil,
                                action: @escaping () -> Void) -> some View {
        modifier(POSModalFlowActionModifier<POSModalFlowBackActionKey>(enabled: enabled,
                                                                       actionEnabled: actionEnabled,
                                                                       accessibilityLabel: POSFullScreenFlowHeaderLocalization.backAccessibilityLabel,
                                                                       accessibilityIdentifier: accessibilityIdentifier,
                                                                       action: action))
    }

    func posModalFlowHeaderTitle(_ title: String?) -> some View {
        preference(key: POSModalFlowHeaderTitleKey.self, value: title)
    }
}

private struct POSFullScreenFlowHeaderModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    let style: POSModalCompactStyle?
    let dismissAction: (() -> Void)?
    @State private var dismissHandler = POSModalFlowAction.Handler()
    @State private var backAction: POSModalFlowAction?
    @State private var contentTitle: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let style, let title = style.fullScreenTitle {
            content
                .environment(\.posModalCompactStyle, style)
                .onPreferenceChange(POSModalFlowBackActionKey.self) { backAction = $0 }
                .onPreferenceChange(POSModalFlowHeaderTitleKey.self) { contentTitle = $0 }
                .safeAreaInset(edge: .top, spacing: metrics.spacing.none) {
                    POSFullScreenFlowHeader(title: contentTitle ?? title,
                                            buttons: .init(hasSteps: style.hasSteps, backAction: backAction, closeAction: closeAction))
                }
        } else {
            content
        }
    }

    private var closeAction: POSModalFlowAction? {
        guard let dismissAction else {
            return nil
        }
        dismissHandler.action = dismissAction
        return POSModalFlowAction(handler: dismissHandler,
                                  isEnabled: true,
                                  accessibilityLabel: POSFullScreenFlowHeaderLocalization.closeAccessibilityLabel,
                                  accessibilityIdentifier: nil)
    }
}

struct POSFullScreenFlowHeaderButtons: Equatable {
    enum Leading: Equatable {
        case back(POSModalFlowAction?)
        case close(POSModalFlowAction)
    }

    let leading: Leading?
    let trailingClose: POSModalFlowAction?

    init(hasSteps: Bool, backAction: POSModalFlowAction?, closeAction: POSModalFlowAction?) {
        if hasSteps {
            // On the first step the arrow closes the flow.
            leading = .back(backAction ?? closeAction)
            trailingClose = closeAction
        } else {
            leading = closeAction.map { .close($0) }
            trailingClose = nil
        }
    }
}

private struct POSFullScreenFlowHeader: View {
    @Environment(\.posMetrics) private var metrics
    let title: String
    let buttons: POSFullScreenFlowHeaderButtons

    var body: some View {
        POSPageHeaderView(title: title,
                          backButtonConfiguration: leadingButtonConfiguration,
                          trailingContent: {
            if let closeAction = buttons.trailingClose {
                POSPageHeaderBackButton(configuration: closeConfiguration(for: closeAction))
            }
        })
        // Ignore the back button set by the page under the modal.
        .environment(\.posHeaderBackButtonConfiguration, nil)
        .environment(\.posHeaderBackButtonIcon, nil)
        // Without a leading button, line the title up with the content and buttons below.
        .padding(.leading, buttons.leading == nil ? metrics.padding.xxLarge - metrics.padding.medium : metrics.padding.none)
    }

    private var leadingButtonConfiguration: POSPageHeaderBackButtonConfiguration? {
        switch buttons.leading {
        case .back(let backAction):
            return .init(state: backAction?.isEnabled == true ? .enabled : .disabled,
                         action: { backAction?.perform() },
                         accessibilityIdentifier: backAction?.accessibilityIdentifier ?? Constants.backAccessibilityIdentifier,
                         accessibilityLabel: POSFullScreenFlowHeaderLocalization.backAccessibilityLabel)
        case .close(let closeAction):
            return closeConfiguration(for: closeAction)
        case .none:
            return nil
        }
    }

    private func closeConfiguration(for closeAction: POSModalFlowAction) -> POSPageHeaderBackButtonConfiguration {
        .init(state: .enabled,
              action: { closeAction.perform() },
              buttonIcon: Constants.closeIcon,
              accessibilityIdentifier: closeAction.accessibilityIdentifier ?? Constants.closeAccessibilityIdentifier,
              accessibilityLabel: closeAction.accessibilityLabel)
    }
}

private extension POSFullScreenFlowHeader {
    enum Constants {
        static let closeIcon = "xmark"
        static let backAccessibilityIdentifier = "pos-modal-flow-back-button"
        static let closeAccessibilityIdentifier = "pos-modal-flow-close-button"
    }
}

private enum POSFullScreenFlowHeaderLocalization {
    static let backAccessibilityLabel = NSLocalizedString(
        "pos.modalFlowHeader.backButton.accessibilityLabel",
        value: "Back",
        comment: "Accessibility label of the back arrow in the header of a full-screen POS flow on phone. "
        + "On the first step of the flow it closes the flow.")

    static let closeAccessibilityLabel = NSLocalizedString(
        "pos.modalFlowHeader.closeButton.accessibilityLabel",
        value: "Close",
        comment: "Accessibility label of the X in the header of a full-screen POS flow on phone.")
}

private struct POSModalFlowActionModifier<Key: PreferenceKey>: ViewModifier where Key.Value == POSModalFlowAction? {
    let enabled: Bool
    let actionEnabled: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String?
    let action: () -> Void
    @State private var handler = POSModalFlowAction.Handler()

    func body(content: Content) -> some View {
        content
            .preference(key: Key.self, value: enabled ? updatedFlowAction : nil)
    }

    private var updatedFlowAction: POSModalFlowAction {
        handler.action = action
        return POSModalFlowAction(handler: handler,
                                  isEnabled: actionEnabled,
                                  accessibilityLabel: accessibilityLabel,
                                  accessibilityIdentifier: accessibilityIdentifier)
    }
}

/// The closure lives in a shared handler, so the preference value doesn't change on every render.
struct POSModalFlowAction: Equatable {
    final class Handler {
        var action: () -> Void = {}
    }

    let handler: Handler
    let isEnabled: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String?

    func perform() {
        handler.action()
    }

    static func == (lhs: POSModalFlowAction, rhs: POSModalFlowAction) -> Bool {
        lhs.handler === rhs.handler
            && lhs.isEnabled == rhs.isEnabled
            && lhs.accessibilityLabel == rhs.accessibilityLabel
            && lhs.accessibilityIdentifier == rhs.accessibilityIdentifier
    }
}

struct POSModalFlowBackActionKey: PreferenceKey {
    static let defaultValue: POSModalFlowAction? = nil

    static func reduce(value: inout POSModalFlowAction?, nextValue: () -> POSModalFlowAction?) {
        value = value ?? nextValue()
    }
}

private struct POSModalFlowHeaderTitleKey: PreferenceKey {
    static let defaultValue: String? = nil

    static func reduce(value: inout String?, nextValue: () -> String?) {
        value = value ?? nextValue()
    }
}
