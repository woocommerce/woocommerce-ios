import SwiftUI

/// A single list row: a title with an optional description between optional leading and trailing
/// slots, on a surface-bright container. Combine cells (separated by ``StoreDivider``) to build lists.
/// `action` makes the whole row a button; a `trailing` slot with its own control (e.g. a toggle) belongs on a row without `action`.
/// `leading` is a single view value and `trailing` a view builder, so a lone trailing closure always fills `trailing:`.
public struct StoreCell<Leading: View, Trailing: View, Supporting: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let description: String?
    private let configuration: StoreCellConfiguration
    private let showsDisclosureIndicator: Bool
    private let action: (() -> Void)?
    private let leading: Leading
    private let trailing: Trailing
    private let supportingContent: Supporting

    /// - Parameters:
    ///   - title: The row's primary text.
    ///   - description: Secondary text shown under the title.
    ///   - configuration: Controls row density and icon tint independently.
    ///   - showsDisclosureIndicator: Shows the trailing chevron that signals the row opens a detail.
    ///   - action: Makes the whole row a button. `nil` renders a static row.
    ///   - leading: A single view before the text, e.g. a ``StoreIconContainer`` or an image.
    ///   - supportingContent: Additional content under the title and description, such as a rating summary.
    ///   - trailing: Content after the text, e.g. a value label, a ``StoreBadge`` or a toggle.
    public init(_ title: String,
                description: String? = nil,
                configuration: StoreCellConfiguration = .init(),
                showsDisclosureIndicator: Bool = false,
                action: (() -> Void)? = nil,
                leading: Leading,
                supportingContent: Supporting = EmptyView(),
                @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.description = description
        self.configuration = configuration
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.action = action
        self.leading = leading
        self.trailing = trailing()
        self.supportingContent = supportingContent
    }

    public var body: some View {
        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(StorePressFeedbackButtonStyle())
        } else {
            content
                .accessibilityElement(children: .contain)
        }
    }

    private var appearance: StoreCellAppearance {
        StoreCellAppearance(isEnabled: isEnabled)
    }

    private var content: some View {
        HStack(alignment: .center, spacing: configuration.density.trailingSpacing) {
            HStack(alignment: .center, spacing: StoreSpacing.s5) {
                leading
                    .foregroundStyle(iconColor)
                text
            }
            trailing
                .foregroundStyle(appearance.slot)
            if showsDisclosureIndicator {
                StoreIcon.AngleRight.regular.image(size: StoreCellConstants.disclosureIconSize)
                    .foregroundStyle(iconColor)
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, StorePadding.p7)
        .padding(.vertical, configuration.density.verticalPadding)
        .frame(minHeight: configuration.density.minimumHeight)
        .background(appearance.background)
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        switch configuration.iconTint {
        case .secondary: appearance.slot
        case .title: appearance.title
        }
    }

    /// Title and description read as one VoiceOver element, whatever the slots hold.
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
            supportingContent
                .foregroundStyle(appearance.description)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Slot-less conveniences

public extension StoreCell where Leading == EmptyView, Trailing == EmptyView, Supporting == EmptyView {
    init(_ title: String,
         description: String? = nil,
         configuration: StoreCellConfiguration = .init(),
         showsDisclosureIndicator: Bool = false,
         action: (() -> Void)? = nil) {
        self.init(title,
                  description: description,
                  configuration: configuration,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: action,
                  leading: EmptyView(),
                  trailing: { EmptyView() })
    }
}

public extension StoreCell where Trailing == EmptyView {
    init(_ title: String,
         description: String? = nil,
         configuration: StoreCellConfiguration = .init(),
         showsDisclosureIndicator: Bool = false,
         action: (() -> Void)? = nil,
         leading: Leading,
         supportingContent: Supporting = EmptyView()) {
        self.init(title,
                  description: description,
                  configuration: configuration,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: action,
                  leading: leading,
                  supportingContent: supportingContent,
                  trailing: { EmptyView() })
    }
}

public extension StoreCell where Leading == EmptyView, Supporting == EmptyView {
    init(_ title: String,
         description: String? = nil,
         configuration: StoreCellConfiguration = .init(),
         showsDisclosureIndicator: Bool = false,
         action: (() -> Void)? = nil,
         @ViewBuilder trailing: () -> Trailing) {
        self.init(title,
                  description: description,
                  configuration: configuration,
                  showsDisclosureIndicator: showsDisclosureIndicator,
                  action: action,
                  leading: EmptyView(),
                  trailing: trailing)
    }
}

/// File-scoped rather than nested in ``StoreCell`` because a generic type can't hold static stored properties.
private enum StoreCellConstants {
    /// The chevron size from the design (18 pt).
    static let disclosureIconSize: StoreIconSize = .medium
}
