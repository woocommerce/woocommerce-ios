import SwiftUI

/// The mark a ``StoreCheckbox`` renders, resolved from its `isOn` / `isIndeterminate` inputs.
enum StoreCheckboxMark {
    case unchecked
    case checked
    case indeterminate
}

/// The `ButtonStyle` backing ``StoreCheckbox``. Kept internal — callers use ``StoreCheckbox``.
///
/// - Note: Draws the box and mark for the resolved ``StoreCheckboxMark``, deriving the disabled
///   presentation from the uniform state-layer rule so it isn't duplicated per tone.
struct StoreCheckboxStyle: ButtonStyle {
    let mark: StoreCheckboxMark
    let variant: StoreCheckboxVariant

    func makeBody(configuration: Configuration) -> some View {
        StoreCheckboxStyleBody(isPressed: configuration.isPressed, mark: mark, variant: variant)
    }
}

/// Reads `@Environment(\.isEnabled)`, which a `ButtonStyle` can only observe from within a view.
private struct StoreCheckboxStyleBody: View {
    @Environment(\.isEnabled) private var isEnabled

    let isPressed: Bool
    let mark: StoreCheckboxMark
    let variant: StoreCheckboxVariant

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: StoreRadius.medium)
                .fill(fillColor)
            if let borderColor {
                RoundedRectangle(cornerRadius: StoreRadius.medium)
                    .strokeBorder(borderColor, lineWidth: StoreStrokeWidth.medium)
            }
            glyph
        }
        .frame(width: Constants.side, height: Constants.side)
        .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
        .contentShape(Rectangle())
        .opacity(isPressed ? Constants.pressedOpacity : 1)
        .animation(.easeOut(duration: StoreMotion.pressDuration), value: isPressed)
    }

    @ViewBuilder private var glyph: some View {
        switch mark {
        case .checked:
            StoreIcon.Check.solid.image(size: .largeIncreased)
                .foregroundStyle(variant.onColor)
        case .indeterminate:
            StoreIcon.Minus.solid.image(size: .largeIncreased)
                .foregroundStyle(variant.onColor)
        case .unchecked:
            EmptyView()
        }
    }

    /// Filled marks carry the color on the box fill; the unchecked box has no fill.
    private var fillColor: Color {
        switch mark {
        case .checked, .indeterminate:
            return isEnabled ? variant.accent : .storeStateLayerOnSurfaceOpacity16
        case .unchecked:
            return .clear
        }
    }

    /// Only the unchecked box shows a border; filled marks rely on the fill for their shape.
    private var borderColor: Color? {
        switch mark {
        case .unchecked:
            return isEnabled ? variant.accent : .storeStateLayerOnSurfaceOpacity16
        case .checked, .indeterminate:
            return nil
        }
    }
}

private extension StoreCheckboxStyleBody {
    enum Constants {
        /// The box side, from the Figma "Size/Large Increased" token (24 pt).
        static let side = StoreIconSize.largeIncreased.value
        static let pressedOpacity: Double = 0.7
    }
}
