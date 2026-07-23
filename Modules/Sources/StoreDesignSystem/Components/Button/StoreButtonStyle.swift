import SwiftUI

/// The `ButtonStyle` backing ``StoreButton``. Kept internal — callers use ``StoreButton``.
///
/// - Note: Applies the variant/size chrome to a native `Button` and derives the disabled
///   presentation from the uniform state-layer rule.
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
            .opacity(configuration.isPressed ? Constants.pressedOpacity : Constants.fullOpacity)
            .animation(.easeOut(duration: StoreMotion.pressDuration), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        guard isEnabled else {
            return variant.enabled.background == nil ? .clear : .storeStateLayerOnSurfaceOpacity08
        }
        return variant.enabled.background ?? .clear
    }

    private var foregroundColor: Color {
        isEnabled ? variant.enabled.foreground : .storeStateLayerOnSurfaceOpacity24
    }

    private var borderColor: Color? {
        guard variant.enabled.border != nil else {
            return nil
        }
        return isEnabled ? variant.enabled.border : .storeStateLayerOnSurfaceOpacity10
    }
}

private extension StoreButtonStyleBody {
    enum Constants {
        static let fullOpacity: Double = 1
        static let pressedOpacity: Double = 0.7
    }
}
