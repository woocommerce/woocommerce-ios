import SwiftUI

/// A horizontal control with mutually exclusive segments for switching between related views.
///
/// - Note: A single appearance and size — the design defines no variants or sizes, so none are
///   modelled. The selected segment carries `.isSelected`. Each segment's tap target is a full
///   ≥44 pt button, while the visible track keeps its compact design height, centered within it.
public struct StoreSegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [Value]
    private let title: (Value) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace

    /// - Parameters:
    ///   - selection: The selected option, expected to be one of `options`. If it isn't (e.g. `options`
    ///     changed and dropped it), no segment is shown selected until one is tapped.
    ///   - options: The segments, in display order. The design supports 2–5. Each `Value` is the
    ///     segment's identity (like a `Picker` tag) and should be unique.
    ///   - title: The label shown for a given option.
    public init(selection: Binding<Value>,
                options: [Value],
                title: @escaping (Value) -> String) {
        self._selection = selection
        self.options = options
        self.title = title
    }

    public var body: some View {
        ZStack {
            track
            segments
        }
        .animation(reduceMotion ? nil : .easeOut(duration: StoreMotion.selectionDuration), value: selection)
    }

    /// The position of the segment matching `selection`, or `nil` when it isn't among `options`.
    /// Resolving to a single index keeps duplicate values from selecting more than one segment (the
    /// first match wins) and an absent selection from selecting any.
    private var selectedIndex: Int? {
        options.firstIndex(of: selection)
    }

    /// The visible capsule and the selected pill, sized to the compact design height. Accessibility is
    /// exposed by ``segments`` — this layer is decorative, so it's hidden from VoiceOver.
    private var track: some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                pill(for: option, isSelected: index == selectedIndex)
            }
        }
        .padding(StorePadding.p1)
        .background(Color.storeTintLayerPrimaryContainerOpacity16)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.full))
        .accessibilityHidden(true)
    }

    /// Full-height (≥44 pt) transparent buttons overlaid on each segment, so the tap target meets the
    /// HIG minimum while the visible ``track`` keeps its compact design height.
    private var segments: some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    selection = option
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: StoreSize.minimumTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title(option))
                .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
                .accessibilityValue(Localization.positionValue(index: index + 1, count: options.count))
            }
        }
    }

    private func pill(for option: Value, isSelected: Bool) -> some View {
        Text(title(option))
            .storeTextStyle(isSelected ? Constants.selectedTextStyle : Constants.unselectedTextStyle)
            .foregroundStyle(isSelected ? Color.storeOnSurface : Color.storeOnPrimaryContainer)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(minHeight: StoreSize.segmentedControlHeight)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: StoreRadius.extraLarge)
                        .fill(Color.storeSurface)
                        .matchedGeometryEffect(id: Constants.selectionID, in: selectionNamespace)
                }
            }
    }
}

/// File-scoped rather than nested in ``StoreSegmentedControl`` because a generic type can't hold
/// static stored properties.
private enum Constants {
    static let selectedTextStyle: StoreTextStyle = .bodySmall.emphasized
    static let unselectedTextStyle: StoreTextStyle = .bodySmall
    static let selectionID = "selectedSegment"
}

private enum Localization {
    /// The positional context VoiceOver reads alongside a segment's label and selected state, e.g.
    /// "2 of 5" — a segmented control conveys position, which the label alone doesn't.
    static func positionValue(index: Int, count: Int) -> String {
        let format = NSLocalizedString(
            "storeSegmentedControl.accessibilityValue.position",
            value: "%1$d of %2$d",
            comment: "VoiceOver position of a segment in a segmented control. %1$d is the position, %2$d the total count."
        )
        return String.localizedStringWithFormat(format, index, count)
    }
}
