import SwiftUI

/// Header of a full-screen POS modal flow on phone: the back arrow at the leading edge when the content offers one,
/// the title, and the close button at the trailing edge.
struct POSModalFlowHeader: View {
    @Environment(\.posMetrics) private var metrics
    let title: String
    let backAction: POSModalFlowAction?
    let closeAction: POSModalFlowAction?

    var body: some View {
        HStack(alignment: .center, spacing: metrics.spacing.medium) {
            if let backAction {
                POSModalFlowHeaderButton(systemImage: "chevron.backward",
                                         accessibilityLabel: Localization.backAccessibilityLabel,
                                         accessibilityIdentifier: backAction.accessibilityIdentifier ?? Constants.backAccessibilityIdentifier,
                                         action: { backAction.action() })
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
                                         action: { closeAction.action() })
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(Image(systemName: systemImage))
                .font(.posButtonSymbolLarge)
                .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
                .frame(width: POSHeaderLayoutConstants.compactBackButtonSize,
                       height: POSHeaderLayoutConstants.compactBackButtonSize)
                .contentShape(Rectangle())
        }
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
    /// Shows `content` as a full-screen POS flow on phone: a header with `title`, the close button that the content
    /// sets with `posModalCloseButton`, and the back arrow that the content sets with `posModalFlowBackAction`.
    /// A `nil` title leaves the view unchanged.
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
    @State private var closeAction: POSModalFlowAction?
    @State private var backAction: POSModalFlowAction?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let title {
            content
                .environment(\.posModalCompactStyle, .fullScreen(title: title))
                .onPreferenceChange(POSModalFlowCloseActionKey.self) { closeAction = $0 }
                .onPreferenceChange(POSModalFlowBackActionKey.self) { backAction = $0 }
                .safeAreaInset(edge: .top, spacing: metrics.spacing.none) {
                    POSModalFlowHeader(title: title, backAction: backAction, closeAction: closeAction)
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
                                                                        accessibilityLabel: accessibilityLabel,
                                                                        accessibilityIdentifier: accessibilityIdentifier,
                                                                        action: action))
    }

    /// Offers `action` as the back arrow of the full-screen flow header on phone, for a flow with steps.
    ///
    /// Set it on every step, the first one too, so the title stays in place: on the first step `action` closes the
    /// flow, on later steps it goes one step back. A flow that never sets it has no back arrow and its title starts at
    /// the leading edge. The arrow is always read as "Back" by VoiceOver.
    func posModalFlowBackAction(enabled: Bool,
                                accessibilityIdentifier: String? = nil,
                                action: @escaping () -> Void) -> some View {
        modifier(POSModalFlowActionModifier<POSModalFlowBackActionKey>(enabled: enabled,
                                                                       accessibilityLabel: "",
                                                                       accessibilityIdentifier: accessibilityIdentifier,
                                                                       action: action))
    }
}

private struct POSModalFlowActionModifier<Key: PreferenceKey>: ViewModifier where Key.Value == POSModalFlowAction? {
    let enabled: Bool
    let accessibilityLabel: String
    let accessibilityIdentifier: String?
    let action: () -> Void
    @State private var flowAction = POSModalFlowAction()

    func body(content: Content) -> some View {
        content
            .preference(key: Key.self, value: enabled ? updatedFlowAction : nil)
    }

    private var updatedFlowAction: POSModalFlowAction {
        flowAction.action = action
        flowAction.accessibilityLabel = accessibilityLabel
        flowAction.accessibilityIdentifier = accessibilityIdentifier
        return flowAction
    }
}

/// An action that a modal's content offers to `POSModalFlowHeader`: the close button, set by `posModalCloseButton`,
/// or the back arrow, set by `posModalFlowBackAction`.
///
/// It is a reference type so the header always calls the content's latest action, while the preference value only
/// changes when the content itself changes.
final class POSModalFlowAction: Equatable {
    var action: () -> Void = {}
    var accessibilityLabel: String = ""
    var accessibilityIdentifier: String?

    static func == (lhs: POSModalFlowAction, rhs: POSModalFlowAction) -> Bool {
        lhs === rhs
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
