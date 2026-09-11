import SwiftUI

/// A single list row: a title with an optional description between optional leading and trailing
/// slots, on a surface-bright container. Combine cells (separated by ``StoreDivider``) to build lists.
///
/// - Note: Pass `action` to make the whole row one tappable button. A `trailing` slot that carries its
///   own control (e.g. a toggle) belongs on a row without `action`, so the row doesn't expose two
///   competing actions. `.disabled(_:)` dims the row and blocks its action.
public struct StoreCell<Leading: View, Trailing: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let description: String?
    private let showsDisclosureIndicator: Bool
    private let action: (() -> Void)?
    private let leading: Leading
    private let trailing: Trailing

    /// - Parameters:
    ///   - title: The row's primary text.
    ///   - description: Secondary text shown under the title.
    ///   - showsDisclosureIndicator: Shows the trailing chevron that signals the row opens a detail.
    ///   - action: Makes the whole row a button. `nil` renders a static row.
    ///   - leading: Content before the text, e.g. a ``StoreIconContainer`` or an image.
    ///   - trailing: Content after the text, e.g. a value label, a ``StoreBadge`` or a toggle.
    public init(_ title: String,
                description: String? = nil,
                showsDisclosureIndicator: Bool = false,
                action: (() -> Void)? = nil,
                @ViewBuilder leading: () -> Leading,
                @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.description = description
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.action = action
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(StoreCellButtonStyle())
        } else {
            content
                .accessibilityElement(children: StoreCellAccessibility.childBehavior(hasTrailingContent: hasTrailingContent))
        }
    }

    private var appearance: StoreCellAppearance {
        StoreCellAppearance(isEnabled: isEnabled)
    }

    private var hasTrailingContent: Bool {
        Trailing.self != EmptyView.self
    }

    private var content: some View {
        HStack(alignment: .center, spacing: StoreSpacing.s6) {
            HStack(alignment: .center, spacing: StoreSpacing.s5) {
                leading
                    .foregroundStyle(appearance.slot)
                text
            }
            trailing
                .foregroundStyle(appearance.slot)
            if showsDisclosureIndicator {
                StoreIcon.AngleRight.regular.image(size: Constants.disclosureIconSize)
                    .foregroundStyle(appearance.slot)
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
            }
        }
        .padding(StorePadding.p7)
        .frame(minHeight: StoreSize.minimumTapTarget)
        .background(appearance.background)
        .contentShape(Rectangle())
    }

    /// The leading visual sits `s5` from the text (the "cell content" spec); the trailing slot and the
    /// disclosure indicator sit `s6` from the content (the row spec).
    private var text: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s1) {
            Text(title)
                .storeTextStyle(.bodyLarge.emphasized)
                .foregroundStyle(appearance.title)
            if let description {
                Text(description)
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(appearance.description)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Slot-less conveniences

public extension StoreCell where Leading == EmptyView, Trailing == EmptyView {
    init(_ title: String,
         description: String? = nil,
         showsDisclosureIndicator: Bool = false,
         action: (() -> Void)? = nil) {
        self.init(title,
                  description: description,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: action,
                  leading: { EmptyView() },
                  trailing: { EmptyView() })
    }
}

public extension StoreCell where Trailing == EmptyView {
    init(_ title: String,
         description: String? = nil,
         showsDisclosureIndicator: Bool = false,
         action: (() -> Void)? = nil,
         @ViewBuilder leading: () -> Leading) {
        self.init(title,
                  description: description,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: action,
                  leading: leading,
                  trailing: { EmptyView() })
    }
}

public extension StoreCell where Leading == EmptyView {
    init(_ title: String,
         description: String? = nil,
         showsDisclosureIndicator: Bool = false,
         action: (() -> Void)? = nil,
         @ViewBuilder trailing: () -> Trailing) {
        self.init(title,
                  description: description,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: action,
                  leading: { EmptyView() },
                  trailing: trailing)
    }
}

/// File-scoped rather than nested in ``StoreCell`` because a generic type can't hold static stored properties.
private enum Constants {
    /// The chevron size from the design (18 pt).
    static let disclosureIconSize: StoreIconSize = .medium
}

/// Renders a tappable row as its plain content plus the module's press feedback — no button tint.
private struct StoreCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Constants.pressedOpacity : 1)
            .animation(.easeOut(duration: StoreMotion.pressDuration), value: configuration.isPressed)
    }

    private enum Constants {
        static let pressedOpacity: Double = 0.7
    }
}
