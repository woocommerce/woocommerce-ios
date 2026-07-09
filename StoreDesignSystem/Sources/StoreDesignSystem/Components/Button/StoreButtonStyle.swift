import SwiftUI

/// The `ButtonStyle` backing ``StoreButton``. Applies the variant/size chrome to a native
/// `Button` and derives the disabled presentation from the uniform Figma state-layer rule.
/// Kept internal — callers use ``StoreButton`` rather than this style directly.
struct StoreButtonStyle: ButtonStyle {
    let variant: StoreButtonVariant
    let size: StoreButtonSize

    func makeBody(configuration: Configuration) -> some View {
        StoreButtonStyleBody(configuration: configuration, variant: variant, size: size)
    }
}

/// Reads `@Environment(\.isEnabled)` and `configuration.isPressed`, which a `ButtonStyle`
/// can only observe from within a view.
private struct StoreButtonStyleBody: View {
    @Environment(\.isEnabled) private var isEnabled

    let configuration: ButtonStyleConfiguration
    let variant: StoreButtonVariant
    let size: StoreButtonSize

    var body: some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay {
                if let borderColor {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .strokeBorder(borderColor, lineWidth: StoreStrokeWidth.medium)
                }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? Constants.pressedOpacity : 1)
            .animation(.easeOut(duration: Constants.pressAnimationDuration), value: configuration.isPressed)
    }

    // Disabled derives from the uniform state-layer rule: a fill becomes on-surface @ 8%,
    // a border becomes @ 10%, and the label/icon becomes @ 24%.

    private var backgroundColor: Color {
        guard isEnabled else {
            return variant.enabled.background == nil ? .clear : .storeStateLayerOnSurface08
        }
        return variant.enabled.background ?? .clear
    }

    private var foregroundColor: Color {
        isEnabled ? variant.enabled.foreground : .storeStateLayerOnSurface24
    }

    private var borderColor: Color? {
        guard variant.enabled.border != nil else {
            return nil
        }
        return isEnabled ? variant.enabled.border : .storeStateLayerOnSurface10
    }
}

private extension StoreButtonStyleBody {
    enum Constants {
        static let pressedOpacity: Double = 0.7
        static let pressAnimationDuration: TimeInterval = 0.15
    }
}
