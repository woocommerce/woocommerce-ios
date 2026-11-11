import SwiftUI

/// Header of a full-screen POS modal flow on phone: the back arrow at the leading edge in a flow with steps, the title,
/// and the close button at the trailing edge.
struct POSModalFlowHeader: View {
    @Environment(\.posMetrics) private var metrics
    let title: String
    let hasSteps: Bool
    let backAction: POSModalFlowAction?
    let closeAction: POSModalFlowAction?

    /// The step's back button when it has one. Otherwise, in a flow with steps, the arrow closes the flow, as on its first step.
    private var arrowAction: POSModalFlowAction? {
        backAction ?? (hasSteps ? closeAction : nil)
    }

    var body: some View {
        HStack(alignment: .center, spacing: metrics.spacing.medium) {
            if hasSteps || backAction != nil {
                POSModalFlowHeaderButton(systemImage: "chevron.backward",
                                         accessibilityLabel: Localization.backAccessibilityLabel,
                                         accessibilityIdentifier: backAction?.accessibilityIdentifier ?? Constants.backAccessibilityIdentifier,
                                         isEnabled: arrowAction?.isEnabled ?? false,
                                         action: { arrowAction?.perform() })
            }

            Text(title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                // Wraps rather than truncating, like `POSPageHeaderView`; translations run longer than English.
                .lineLimit(Constants.titleLineLimit)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: metrics.spacing.none)

            if let closeAction {
                POSModalFlowHeaderButton(systemImage: "xmark",
                                         accessibilityLabel: closeAction.accessibilityLabel,
                                         accessibilityIdentifier: closeAction.accessibilityIdentifier ?? Constants.closeAccessibilityIdentifier,
                                         isEnabled: closeAction.isEnabled,
                                         action: { closeAction.perform() })
            } else {
                // A step without a close button keeps its space, so the title wraps the same way on every step.
                Color.clear
                    .frame(width: POSHeaderLayoutConstants.compactBackButtonSize,
                           height: POSHeaderLayoutConstants.compactBackButtonSize)
                    .accessibilityHidden(true)
            }
        }
        .foregroundColor(Color.posOnSurface)
        .frame(minHeight: POSHeaderLayoutConstants.minHeight)
        .padding(.horizontal, metrics.padding.medium)
        .padding(.top, metrics.padding.medium)
        .padding(.bottom, metrics.padding.large)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct POSModalFlowHeaderButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(Image(systemName: systemImage))
                .font(.posButtonSymbolLarge)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .foregroundColor(isEnabled ? .posOnSurface : .posOnSurfaceVariantLowest)
                .frame(width: POSHeaderLayoutConstants.compactBackButtonSize,
                       height: POSHeaderLayoutConstants.compactBackButtonSize)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private extension POSModalFlowHeader {
    enum Constants {
        static let titleLineLimit: Int = 2
        static let backAccessibilityIdentifier = "pos-modal-flow-back-button"
        static let closeAccessibilityIdentifier = "pos-modal-flow-close-button"
    }

    enum Localization {
        static let backAccessibilityLabel = NSLocalizedString(
            "pos.modalFlowHeader.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label of the back arrow in the header of a full-screen POS flow on phone. "
            + "On the first step of the flow it closes the flow.")
    }
}

extension View {
    /// Shows `content` as a full-screen POS flow on phone when `style` is `.fullScreen`: a header with its title, the close
    /// button that the content sets with `posModalCloseButton`, and the back arrow that the content sets with
    /// `posModalFlowBackAction`. Any other style leaves the view unchanged.
    ///
    /// `posModal` applies it for `.fullScreen`. Apply it directly only inside a presentation that is not a `posModal`,
    /// such as a full-screen cover.
    func posFullScreenFlowHeader(style: POSModalCompactStyle?) -> some View {
        modifier(POSFullScreenFlowHeaderModifier(style: style))
    }
}

private struct POSFullScreenFlowHeaderModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    let style: POSModalCompactStyle?
    @State private var closeAction: POSModalFlowAction?
    @State private var backAction: POSModalFlowAction?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let style, let title = style.fullScreenTitle {
            content
                .environment(\.posModalCompactStyle, style)
                .onPreferenceChange(POSModalFlowCloseActionKey.self) { closeAction = $0 }
                .onPreferenceChange(POSModalFlowBackActionKey.self) { backAction = $0 }
                .safeAreaInset(edge: .top, spacing: metrics.spacing.none) {
                    POSModalFlowHeader(title: title, hasSteps: style.hasSteps, backAction: backAction, closeAction: closeAction)
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
        modifier(POSModalFlowActionModifier<POSModalFlowCloseActionKey>(enabled: enabled,
                                                                        actionEnabled: true,
                                                                        accessibilityLabel: accessibilityLabel,
                                                                        accessibilityIdentifier: accessibilityIdentifier,
                                                                        action: action))
    }

    /// Offers `action` as the back arrow of the full-screen flow header on phone, for the current step of a flow with steps
    /// (`.fullScreen(title:hasSteps: true)`). `POSFlowButtonsView` sets it for a button marked `isBack`, so a flow does not
    /// call it directly. On a step that offers none, the arrow closes the flow. The arrow is always read as "Back".
    func posModalFlowBackAction(enabled: Bool,
                                actionEnabled: Bool = true,
                                accessibilityIdentifier: String? = nil,
                                action: @escaping () -> Void) -> some View {
        modifier(POSModalFlowActionModifier<POSModalFlowBackActionKey>(enabled: enabled,
                                                                       actionEnabled: actionEnabled,
                                                                       accessibilityLabel: "",
                                                                       accessibilityIdentifier: accessibilityIdentifier,
                                                                       action: action))
    }
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

/// An action that a modal's content offers to `POSModalFlowHeader`: the close button, set by `posModalCloseButton`,
/// or the back arrow, set by `posModalFlowBackAction`.
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
