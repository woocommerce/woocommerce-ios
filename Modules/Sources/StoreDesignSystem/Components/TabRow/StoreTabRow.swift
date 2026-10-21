import SwiftUI

/// A row of equal-width tabs for switching between sibling views, with a primary indicator under
/// the selected tab and a hairline under the row.
///
/// - Note: The design defines a single fixed, primary style, so no variants or sizes are modelled;
///   a scrollable row is not in the design. The selected tab carries `.isSelected`, and the
///   indicator slides between tabs unless Reduce Motion is on. The row owns no state: the caller
///   passes the `selection` binding and the tabs. Keep to 3–5 tabs (design guidance).
public struct StoreTabRow<Value: Hashable>: View {
    @Binding private var selection: Value
    private let tabs: [StoreTab<Value>]

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var indicatorNamespace

    /// - Parameters:
    ///   - selection: The selected tab's value, expected to be one of `tabs`. If it isn't (e.g. `tabs`
    ///     changed and dropped it), no tab is shown selected until one is tapped.
    ///   - tabs: The tabs, in display order. Each value should be unique.
    public init(selection: Binding<Value>, tabs: [StoreTab<Value>]) {
        self._selection = selection
        self.tabs = tabs
    }

    public var body: some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tabButton(tab, isSelected: index == selectedIndex, position: index + 1)
            }
        }
        .background(alignment: .bottom) {
            StoreDivider()
        }
        .background(appearance.background)
        .animation(reduceMotion ? nil : .easeOut(duration: StoreMotion.selectionDuration), value: selection)
    }

    private var appearance: StoreTabRowAppearance {
        StoreTabRowAppearance(isEnabled: isEnabled)
    }

    /// The position of the tab matching `selection`, or `nil` when it isn't among `tabs`.
    /// Resolving to a single index keeps duplicate values from selecting more than one tab (the
    /// first match wins) and an absent selection from selecting any.
    private var selectedIndex: Int? {
        tabs.firstIndex { $0.value == selection }
    }

    /// A full-height, full-width tab. The icon is decorative: the title alone is the VoiceOver label.
    private func tabButton(_ tab: StoreTab<Value>, isSelected: Bool, position: Int) -> some View {
        let layout = StoreTabRowLayout(hasIcon: tab.icon != nil)
        return Button {
            selection = tab.value
        } label: {
            VStack(spacing: StoreSpacing.s4) {
                tab.icon?.image(size: Constants.iconSize)
                    .accessibilityHidden(true)
                Text(tab.title)
                    .storeTextStyle(Constants.textStyle)
                    .lineLimit(1)
            }
            .foregroundStyle(appearance.foreground)
            .padding(.horizontal, StorePadding.p5)
            .padding(.bottom, layout.bottomInset)
            .frame(maxWidth: .infinity,
                   minHeight: StoreSize.tabRowHeight,
                   maxHeight: .infinity,
                   alignment: layout.contentAlignment)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isSelected {
                    indicator
                }
            }
        }
        .buttonStyle(StorePressFeedbackButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(Localization.positionValue(index: position, count: tabs.count))
    }

    private var indicator: some View {
        RoundedRectangle(cornerRadius: StoreRadius.small)
            .fill(appearance.indicator)
            .frame(height: StoreStrokeWidth.thick)
            .matchedGeometryEffect(id: Constants.indicatorID, in: indicatorNamespace)
    }
}

/// File-scoped rather than nested in ``StoreTabRow`` because a generic type can't hold
/// static stored properties.
private enum Constants {
    static let textStyle: StoreTextStyle = .labelMedium.emphasized
    static let iconSize: StoreIconSize = .medium
    static let indicatorID = "selectedTabIndicator"
}

private enum Localization {
    /// The positional context VoiceOver reads alongside a tab's label and selected state, e.g. "2 of 3".
    static func positionValue(index: Int, count: Int) -> String {
        let format = NSLocalizedString(
            "storeTabRow.accessibilityValue.position",
            value: "%1$d of %2$d",
            comment: "VoiceOver position of a tab in a tab row. %1$d is the position, %2$d the total count."
        )
        return String.localizedStringWithFormat(format, index, count)
    }
}

#Preview("Light") {
    TabRowPreview()
}

#Preview("Dark") {
    TabRowPreview()
        .preferredColorScheme(.dark)
}

private struct TabRowPreview: View {
    @State private var iconSelection = 0
    @State private var textSelection = 1

    private let iconTabs = [
        StoreTab(0, title: "Products", icon: StoreIcon.Box.regular),
        StoreTab(1, title: "Orders", icon: StoreIcon.List.regular),
        StoreTab(2, title: "More", icon: StoreIcon.CircleInfo.regular)
    ]
    private let textTabs = [
        StoreTab(0, title: "Products"),
        StoreTab(1, title: "Orders"),
        StoreTab(2, title: "More")
    ]

    var body: some View {
        VStack(spacing: StoreSpacing.s5) {
            StoreTabRow(selection: $iconSelection, tabs: iconTabs)
            StoreTabRow(selection: $textSelection, tabs: textTabs)
            StoreTabRow(selection: .constant(0), tabs: textTabs)
                .disabled(true)
        }
        .padding(.vertical, StorePadding.p5)
        .background(Color.storeSectionBackground)
    }
}
