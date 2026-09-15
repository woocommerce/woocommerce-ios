import SwiftUI

/// The bar at the top of a screen: a title with optional supporting text, an optional navigation
/// control (back / close), and up to three trailing icon actions, on a surface-bright container.
///
/// - Note: The bar is static. The screen decides when its content has scrolled under the bar and
///   toggles `showsDivider`; the medium bar collapsing to small on scroll is a separate, later
///   piece. `.disabled(_:)` dims the text and controls and blocks every action.
public struct StoreTopAppBar: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let supportingText: String?
    private let size: StoreTopAppBarSize
    private let alignment: StoreTopAppBarTitleAlignment
    private let navigation: StoreTopAppBarNavigation?
    private let actions: [StoreTopAppBarAction]
    private let showsDivider: Bool

    /// - Parameters:
    ///   - title: The screen's title. Single line; truncates at the end.
    ///   - supportingText: Secondary text under the title, e.g. the store name.
    ///   - size: `.small` (one row) or `.medium` (title on its own row under the controls).
    ///   - alignment: Where the text sits horizontally.
    ///   - navigation: The leading back / close control. `nil` hides it (section app bars).
    ///   - actions: Trailing icon actions, laid out from the trailing edge in the given order.
    ///   - showsDivider: Draws the bottom divider that marks content scrolled under the bar.
    public init(_ title: String,
                supportingText: String? = nil,
                size: StoreTopAppBarSize = .small,
                alignment: StoreTopAppBarTitleAlignment = .leading,
                navigation: StoreTopAppBarNavigation? = nil,
                actions: [StoreTopAppBarAction] = [],
                showsDivider: Bool = false) {
        self.title = title
        self.supportingText = supportingText
        self.size = size
        self.alignment = alignment
        self.navigation = navigation
        self.actions = actions
        self.showsDivider = showsDivider
    }

    public var body: some View {
        layoutBody
            .background(appearance.background)
            .overlay(alignment: .bottom) {
                if showsDivider {
                    StoreDivider()
                }
            }
    }

    @ViewBuilder private var layoutBody: some View {
        switch size {
        case .small:
            smallLayout
        case .medium:
            mediumLayout
        }
    }

    private var appearance: StoreTopAppBarAppearance {
        StoreTopAppBarAppearance(isEnabled: isEnabled)
    }

    private var layout: StoreTopAppBarLayout {
        StoreTopAppBarLayout(size: size, hasNavigation: navigation != nil, actionCount: actions.count)
    }

    // MARK: - Layouts

    /// One row. Leading-aligned text sits between the controls. Centered text centers on the bar
    /// while it fits inside the controls' symmetric inset, then slides toward the free side and
    /// only truncates once it fills the space between the controls, as `UINavigationBar` does.
    private var smallLayout: some View {
        HStack(spacing: StoreSpacing.s0) {
            navigationControl
            if alignment == .leading {
                text
                    .padding(.leading, layout.textLeadingInset)
                    .padding(.trailing, layout.textTrailingInset)
            } else {
                centeringBalance(maxWidth: layout.leadingCenteringBalance)
                Spacer(minLength: StoreSpacing.s0)
                textStack
                    .padding(.horizontal, layout.centeredTextGap)
                    .layoutPriority(LayoutPriority.text)
                Spacer(minLength: StoreSpacing.s0)
                centeringBalance(maxWidth: layout.trailingCenteringBalance)
            }
            actionControls
        }
        .frame(minHeight: StoreSize.topAppBarControlSize)
        .padding(.vertical, StorePadding.p3)
        .padding(.leading, layout.barLeadingInset)
        .padding(.trailing, StorePadding.p2)
    }

    /// Pads the narrower control cluster up to the wider one. Sized after the text, so it yields
    /// before the text truncates, and before the plain spacers, so centering stays exact while it fits.
    private func centeringBalance(maxWidth: CGFloat) -> some View {
        Spacer(minLength: StoreSpacing.s0)
            .frame(maxWidth: maxWidth)
            .layoutPriority(LayoutPriority.centeringBalance)
    }

    /// Two rows: the controls row keeps its height even when empty, so the title always sits at
    /// the same position. The design's `s3` row gap and `p4` bottom padding are measured to the
    /// title's cap height and baseline; the font's line box carries the rest, hence `s1` / `p3`.
    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s1) {
            HStack(spacing: StoreSpacing.s0) {
                navigationControl
                Spacer(minLength: StoreSpacing.s0)
                actionControls
            }
            .frame(minHeight: StoreSize.topAppBarControlSize)
            .padding(.top, StorePadding.p3)
            .padding(.leading, layout.barLeadingInset)
            .padding(.trailing, StorePadding.p2)

            text
                .padding(.leading, layout.textLeadingInset)
                .padding(.trailing, alignment == .center ? layout.textLeadingInset : layout.textTrailingInset)
        }
        .padding(.bottom, StorePadding.p3)
    }

    // MARK: - Parts

    /// Title and supporting text read as one VoiceOver heading, after the navigation control and
    /// before the actions whatever the layout puts on screen first. Line spacing is `s0`: the
    /// design's `s3` gap is measured between cap height and baseline, which the fonts' own line
    /// boxes already provide.
    private var text: some View {
        textStack
            .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
    }

    /// The text without a flexible frame, for layouts that size it to its content.
    private var textStack: some View {
        VStack(alignment: alignment.horizontalAlignment, spacing: StoreSpacing.s0) {
            Text(title)
                .storeTextStyle(size.titleStyle)
                .foregroundStyle(appearance.title)
            if let supportingText {
                Text(supportingText)
                    .storeTextStyle(size.supportingTextStyle)
                    .foregroundStyle(appearance.supportingText)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilitySortPriority(AccessibilityOrder.text)
    }

    @ViewBuilder private var navigationControl: some View {
        if let navigation {
            StoreTopAppBarControl(icon: navigation.icon,
                                  accessibilityLabel: navigation.accessibilityLabel,
                                  flipsForRightToLeft: navigation.flipsForRightToLeft,
                                  action: navigation.action)
                .accessibilitySortPriority(AccessibilityOrder.navigation)
        }
    }

    private var actionControls: some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                StoreTopAppBarControl(icon: action.icon,
                                      accessibilityLabel: action.accessibilityLabel,
                                      flipsForRightToLeft: false,
                                      action: action.action)
                    .disabled(!action.isEnabled)
            }
        }
        .accessibilitySortPriority(AccessibilityOrder.actions)
    }

    /// Sizing order in the centered small row: text first, then the centering balance, then the
    /// plain spacers.
    private enum LayoutPriority {
        static let text: Double = 2
        static let centeringBalance: Double = 1
    }

    /// VoiceOver order: navigation, text, actions. Higher reads first.
    private enum AccessibilityOrder {
        static let navigation: Double = 3
        static let text: Double = 2
        static let actions: Double = 1
    }
}

/// A 48 pt icon button: the 24 pt glyph centered in the design's control box.
private struct StoreTopAppBarControl: View {
    @Environment(\.isEnabled) private var isEnabled

    let icon: StoreIconImage
    let accessibilityLabel: String
    let flipsForRightToLeft: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon.image(size: Constants.iconSize)
                .flipsForRightToLeftLayoutDirection(flipsForRightToLeft)
                .foregroundStyle(StoreTopAppBarAppearance(isEnabled: isEnabled).control)
                .frame(width: StoreSize.topAppBarControlSize, height: StoreSize.topAppBarControlSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(StorePressFeedbackButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }

    private enum Constants {
        /// The glyph size from the design (24 pt).
        static let iconSize: StoreIconSize = .largeIncreased
    }
}
