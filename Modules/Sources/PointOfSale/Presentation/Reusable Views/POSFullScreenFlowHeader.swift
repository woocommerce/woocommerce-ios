import SwiftUI

extension View {
    /// Shows `content` as a full-screen POS flow on phone when `style` is `.fullScreen`: a POS page header with the title,
    /// the content below it. Any other style leaves the view unchanged.
    ///
    /// The header buttons come from the content: the close button from `posModalCloseButton` or
    /// `posModalFlowHeaderCloseButton`, the back arrow of a flow with steps from `posModalFlowBackAction`.
    ///
    /// `posModal` applies it for `.fullScreen`. Apply it directly only inside a presentation that is not a `posModal`,
    /// such as a full-screen cover.
    func posFullScreenFlowHeader(style: POSModalCompactStyle?) -> some View {
        modifier(POSFullScreenFlowHeaderModifier(style: style))
    }

    /// Offers `action` as the close button of the full-screen flow header, without adding a close button to the content.
    /// Use it for content that lays itself out, such as a scrolling list; `posModalCloseButton` also centers the content.
    func posModalFlowCloseAction(enabled: Bool,
                                 accessibilityLabel: String,
                                 accessibilityIdentifier: String? = nil,
                                 action: @escaping () -> Void) -> some View {
        modifier(POSModalFlowActionModifier<POSModalFlowCloseActionKey>(enabled: enabled,
                                                                        actionEnabled: true,
                                                                        accessibilityLabel: accessibilityLabel,
                                                                        accessibilityIdentifier: accessibilityIdentifier,
                                                                        action: action))
    }

    /// Offers `action` as the back arrow of the full-screen flow header on phone, for the current step of a flow with steps
    /// (`.fullScreen(title:hasSteps: true)`). On a step that offers none, the arrow closes the flow.
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

    /// Replaces the title of the full-screen flow header on phone while this content is shown, for a step that would
    /// otherwise repeat its own title under the flow title. `nil` keeps the flow title.
    func posModalFlowHeaderTitle(_ title: String?) -> some View {
        preference(key: POSModalFlowHeaderTitleKey.self, value: title)
    }
}

private struct POSFullScreenFlowHeaderModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    let style: POSModalCompactStyle?
    @State private var closeAction: POSModalFlowAction?
    @State private var backAction: POSModalFlowAction?
    @State private var contentTitle: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let style, let title = style.fullScreenTitle {
            content
                .environment(\.posModalCompactStyle, style)
                .onPreferenceChange(POSModalFlowCloseActionKey.self) { closeAction = $0 }
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
}

/// Which buttons the header of a full-screen flow shows.
///
/// A flow with steps has the back arrow at the leading edge and the close button at the trailing edge.
/// A flow without steps has the close button at the leading edge, where other POS pages have theirs.
/// When the content offers no close action the header has the title only.
struct POSFullScreenFlowHeaderButtons: Equatable {
    enum Leading: Equatable {
        case back(POSModalFlowAction?)
        case close(POSModalFlowAction)
    }

    let leading: Leading?
    let trailingClose: POSModalFlowAction?

    init(hasSteps: Bool, backAction: POSModalFlowAction?, closeAction: POSModalFlowAction?) {
        if hasSteps {
            // A step without its own back button, such as the first one, closes the flow with the arrow.
            leading = .back(backAction ?? closeAction)
            trailingClose = closeAction
        } else {
            leading = closeAction.map { .close($0) }
            trailingClose = nil
        }
    }
}

private struct POSFullScreenFlowHeader: View {
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
        // The header belongs to the flow, so it ignores the back button that the page under the modal set for its own header.
        .environment(\.posHeaderBackButtonConfiguration, nil)
        .environment(\.posHeaderBackButtonIcon, nil)
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

/// An action that a modal's content offers to the full-screen flow header: the close button or the back arrow.
///
/// The closure lives in a shared handler, so the header always calls the content's latest action while the preference
/// value only changes when the handler or the shown state changes.
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

struct POSModalFlowCloseActionKey: PreferenceKey {
    static let defaultValue: POSModalFlowAction? = nil

    static func reduce(value: inout POSModalFlowAction?, nextValue: () -> POSModalFlowAction?) {
        value = value ?? nextValue()
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
