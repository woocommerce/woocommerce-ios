import SwiftUI

/// A design-system button: a text label with an optional leading icon, styled per the
/// Mobile Design System. It wraps a native `Button`, so it inherits button accessibility
/// traits, focus, and `.disabled(_:)` behavior for free.
///
/// ```swift
/// StoreButton("Save") { save() }
/// StoreButton("Add", icon: StoreIcon.Plus.regular, variant: .tonal, size: .medium) { add() }
/// StoreButton("Continue") { next() }
///     .disabled(!isFormValid)
/// ```
///
/// The button hugs its content. Add `.frame(maxWidth: .infinity)` for a full-width button.
public struct StoreButton: View {
    private let title: String
    private let icon: StoreIconImage?
    private let variant: StoreButtonVariant
    private let size: StoreButtonSize
    private let action: () -> Void

    public init(_ title: String,
                icon: StoreIconImage? = nil,
                variant: StoreButtonVariant = .filled,
                size: StoreButtonSize = .small,
                action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: StoreSpacing.s3) {
                icon?.image(size: size.iconSize)
                Text(title).storeTextStyle(size.textStyle)
            }
        }
        .buttonStyle(StoreButtonStyle(variant: variant, size: size))
    }
}

#if DEBUG
#Preview("StoreButton") {
    ScrollView {
        VStack(alignment: .leading, spacing: StoreSpacing.s6) {
            ForEach(["filled", "tonal", "outlined"], id: \.self) { variantName in
                let variant: StoreButtonVariant = variantName == "filled" ? .filled
                    : variantName == "tonal" ? .tonal : .outlined
                VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                    Text(variantName).storeTextStyle(.labelSmall)
                    HStack(spacing: StoreSpacing.s4) {
                        StoreButton("Label", icon: StoreIcon.Plus.regular, variant: variant, size: .small) {}
                        StoreButton("Label", icon: StoreIcon.Plus.regular, variant: variant, size: .medium) {}
                    }
                    HStack(spacing: StoreSpacing.s4) {
                        StoreButton("Label", icon: StoreIcon.Plus.regular, variant: variant, size: .small) {}
                            .disabled(true)
                        StoreButton("Label", icon: StoreIcon.Plus.regular, variant: variant, size: .medium) {}
                            .disabled(true)
                    }
                }
            }
        }
        .padding()
    }
}
#endif
