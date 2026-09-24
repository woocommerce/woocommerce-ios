import SwiftUI

/// A compact control that represents a filter or selection in context: a label between optional leading
/// and trailing icons, outlined while resting and tonal while selected.
///
/// - Note: The design defines a single outlined style and no sizes, so none are modelled. The visible
///   chip keeps its compact design height while the tap target extends to the HIG minimum, as
///   ``StoreSegmentedControl`` does. The selected chip carries `.isSelected` for VoiceOver.
///   The chip owns no state: the caller passes `isSelected` and decides what a tap means in `action`.
public struct StoreFilterChip: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let icon: StoreIconImage?
    private let isSelected: Bool
    private let trailingIcon: StoreIconImage?
    private let action: () -> Void

    /// - Parameters:
    ///   - title: The chip's label.
    ///   - icon: An optional leading icon, e.g. a filter glyph or a sort direction arrow.
    ///   - isSelected: Whether the filter is applied. The caller owns the state and flips it in `action`.
    ///   - trailingIcon: An optional trailing icon, e.g. `StoreIcon.AngleDown.regular` when the chip opens further options.
    ///   - action: Called on tap.
    public init(_ title: String,
                icon: StoreIconImage? = nil,
                isSelected: Bool,
                trailingIcon: StoreIconImage? = nil,
                action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.trailingIcon = trailingIcon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            chip
                .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(StorePressFeedbackButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var appearance: StoreFilterChipAppearance {
        StoreFilterChipAppearance(isSelected: isSelected, isEnabled: isEnabled)
    }

    /// The visible chip. Icons are decorative: the title alone is the VoiceOver label.
    private var chip: some View {
        HStack(spacing: StoreSpacing.s3) {
            icon?.image(size: Constants.iconSize)
                .accessibilityHidden(true)
            Text(title)
                .storeTextStyle(Constants.textStyle)
                .lineLimit(1)
            trailingIcon?.image(size: Constants.iconSize)
                .accessibilityHidden(true)
        }
        .foregroundStyle(appearance.foreground)
        .padding(.horizontal, StorePadding.p4)
        .frame(minHeight: StoreSize.filterChipHeight)
        .background(appearance.background)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.large))
        .overlay {
            if let border = appearance.border {
                RoundedRectangle(cornerRadius: StoreRadius.large)
                    .strokeBorder(border, lineWidth: StoreStrokeWidth.regular)
            }
        }
    }
}

private extension StoreFilterChip {
    enum Constants {
        static let textStyle: StoreTextStyle = .bodyMedium.emphasized
        static let iconSize: StoreIconSize = .extraSmall
    }
}

#Preview("Light") {
    FilterChipPreview()
}

#Preview("Dark") {
    FilterChipPreview()
        .preferredColorScheme(.dark)
}

private struct FilterChipPreview: View {
    @State private var isSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s3) {
            HStack(spacing: StoreSpacing.s3) {
                StoreFilterChip("Label", isSelected: false) {}
                StoreFilterChip("Label", isSelected: false, trailingIcon: StoreIcon.AngleDown.regular) {}
                StoreFilterChip("Label", icon: StoreIcon.BarsFilter.regular, isSelected: false) {}
                StoreFilterChip("Label", icon: StoreIcon.BarsFilter.regular, isSelected: false, trailingIcon: StoreIcon.AngleDown.regular) {}
            }
            HStack(spacing: StoreSpacing.s3) {
                StoreFilterChip("Label", isSelected: true) {}
                StoreFilterChip("Label", isSelected: true, trailingIcon: StoreIcon.AngleDown.regular) {}
                StoreFilterChip("Label", icon: StoreIcon.BarsFilter.regular, isSelected: true) {}
                StoreFilterChip("Label", icon: StoreIcon.BarsFilter.regular, isSelected: true, trailingIcon: StoreIcon.AngleDown.regular) {}
            }
            HStack(spacing: StoreSpacing.s3) {
                StoreFilterChip("Disabled", isSelected: false) {}
                StoreFilterChip("Disabled", isSelected: true) {}
            }
            .disabled(true)
            StoreFilterChip("Toggle me", icon: StoreIcon.BarsFilter.regular, isSelected: isSelected) {
                isSelected.toggle()
            }
        }
        .padding(StorePadding.p5)
        .background(Color.storeSurface)
    }
}
