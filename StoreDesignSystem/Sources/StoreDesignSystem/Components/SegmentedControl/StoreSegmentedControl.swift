import SwiftUI

/// A horizontal control with mutually exclusive segments for switching between related views.
///
/// - Note: A single appearance and size — the design defines no variants or sizes, so none are
///   modelled. Each segment is its own button (the selected one carries `.isSelected`); the track
///   height follows the segment's cap-height rather than a literal vertical padding, and the
///   per-segment hit target is below the 44 pt minimum by design, as with other compact controls.
public struct StoreSegmentedControl<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [Value]
    private let title: (Value) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace

    /// - Parameters:
    ///   - selection: The currently selected option.
    ///   - options: The segments, in display order. Each `Value` is the segment's identity (like a
    ///     `Picker` tag) and must be unique — but `title` may repeat, so two segments can show the
    ///     same text as long as their underlying value differs.
    ///   - title: The label shown for a given option.
    public init(selection: Binding<Value>,
                options: [Value],
                title: @escaping (Value) -> String) {
        self._selection = selection
        self.options = options
        self.title = title
    }

    public var body: some View {
        HStack(spacing: StoreSpacing.s0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                segment(for: option, at: index)
            }
        }
        .padding(StorePadding.p1)
        .background(Color.storeTintLayerPrimaryContainerOpacity16)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.full))
        .animation(reduceMotion ? nil : .easeOut(duration: StoreMotion.selectionDuration), value: selection)
    }

    @ViewBuilder
    private func segment(for option: Value, at index: Int) -> some View {
        let isSelected = option == selection
        Button {
            selection = option
        } label: {
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
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(Localization.positionValue(index: index + 1, count: options.count))
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
