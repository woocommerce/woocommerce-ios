import SwiftUI

/// The visual variant of the POS button.
enum POSButtonVariant {
    case filled
    case outlined
}

/// The size variant of the POS button.
enum POSButtonSize {
    case normal
    case extraSmall
}

/// A unified button style for POS that supports different variants and sizes.
struct POSButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled

    let variant: POSButtonVariant
    let size: POSButtonSize

    init(variant: POSButtonVariant = .filled,
         size: POSButtonSize = .normal) {
        self.variant = variant
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch size {
            case .normal:
                HStack {
                    Spacer()
                    configuration.label
                    Spacer()
                }
            case .extraSmall:
                configuration.label
            }
        }
        .padding(.vertical, size.padding.vertical)
        .padding(.horizontal, size.padding.horizontal)
        .font(size.font)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .overlay(borderOverlay)
        // Makes the entire area tappable, otherwise the area with clear background is not tappable.
        .contentShape(Rectangle())
        .cornerRadius(Constants.cornerRadius)
        .opacity(configuration.isPressed ? 0.7 : 1.0)
        .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        switch (variant, isEnabled) {
        case (.filled, true):
                .posPrimaryContainer
        case (.filled, false):
                .posDisabledContainer
        case (.outlined, _):
                .clear
        }
    }

    private var foregroundColor: Color {
        switch (variant, isEnabled) {
        case (.filled, true):
                .posOnPrimaryContainer
        case (.filled, false):
                .posOnDisabledContainer
        case (.outlined, true):
                .posOnSurface
        case (.outlined, false):
                .posOnDisabledContainer
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if variant == .outlined {
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .strokeBorder(isEnabled ? Color.posInverseSurface : .posDisabledContainer,
                              lineWidth: Constants.borderStrokeWidth)
        }
    }
}

// MARK: - POSButtonStyle Constants

private extension POSButtonStyle {
    enum Constants {
        static let cornerRadius: CGFloat = 8.0
        static let borderStrokeWidth: CGFloat = 2.0
    }
}

// MARK: - POSButtonSize Extensions

private extension POSButtonSize {
    var padding: (vertical: CGFloat, horizontal: CGFloat) {
        switch self {
        case .normal:
            (vertical: 24, horizontal: 24)
        case .extraSmall:
            (vertical: 8, horizontal: 16)
        }
    }

    var font: POSFontStyle {
        switch self {
        case .normal:
                .posBodyLargeEmphasized
        case .extraSmall:
                .posBodyMediumEmphasized
        }
    }
}

// MARK: - Preview

#if DEBUG

struct POSButtonStyle_Previews: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                previewSection(title: "Filled Buttons - Normal",
                               variant: .filled, size: .normal)

                previewSection(title: "Filled Buttons - Extra Small",
                               variant: .filled, size: .extraSmall)

                previewSection(title: "Outlined Buttons - Normal",
                               variant: .outlined, size: .normal)

                previewSection(title: "Outlined Buttons - Extra Small",
                               variant: .outlined, size: .extraSmall)

                // Example with long text
                VStack(alignment: .leading, spacing: 16) {
                    Text("Long Text Examples")
                        .font(.headline)

                    Button("This is a very long button text that might wrap to multiple lines") {}
                        .buttonStyle(POSButtonStyle(variant: .filled, size: .normal))

                    Button("Long text in small size button that might need to wrap") {}
                        .buttonStyle(POSButtonStyle(variant: .outlined, size: .extraSmall))
                }
            }
            .padding()
        }
    }

    private func previewSection(title: String, variant: POSButtonVariant, size: POSButtonSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            Button("Enabled Button") {}
                .buttonStyle(POSButtonStyle(variant: variant, size: size))

            Button("Disabled Button") {}
                .buttonStyle(POSButtonStyle(variant: variant, size: size))
                .disabled(true)
        }
    }
}

#Preview("Button Styles") {
    POSButtonStyle_Previews()
}

#endif
