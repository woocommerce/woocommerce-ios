import SwiftUI

/// The radio visual — the ring (unselected) or the filled dot (selected) — with no interactivity or
/// tap target. Shared by ``StoreRadioButton`` (a single control) and ``StoreRadioGroup`` (a row's mark).
///
/// - Note: Reads `@Environment(\.isEnabled)` to derive the disabled presentation from the uniform
///   state-layer rule, so it isn't spelled out per state.
struct StoreRadioButtonIndicator: View {
    @Environment(\.isEnabled) private var isEnabled

    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(accentColor)
                Circle()
                    .fill(dotColor)
                    .frame(width: Constants.dot, height: Constants.dot)
            } else {
                Circle()
                    .strokeBorder(accentColor, lineWidth: StoreStrokeWidth.medium)
            }
        }
        .frame(width: Constants.side, height: Constants.side)
    }

    /// The unselected ring and the selected fill share one accent; disabled drops to the state layer.
    private var accentColor: Color {
        isEnabled ? .storePrimary : .storeStateLayerOnSurfaceOpacity16
    }

    /// The selected inner dot: on-primary when enabled, a dimmer state layer when disabled.
    private var dotColor: Color {
        isEnabled ? .storeOnPrimary : .storeStateLayerOnSurfaceOpacity24
    }
}

private extension StoreRadioButtonIndicator {
    enum Constants {
        /// The control diameter (24 pt).
        static let side = StoreIconSize.largeIncreased.value
        /// The selected inner-dot diameter (8 pt).
        static let dot: CGFloat = StoreSpacing.s3
    }
}
