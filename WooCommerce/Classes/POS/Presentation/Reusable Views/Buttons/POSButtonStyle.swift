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

/// Filled button style in POS that can show a loading indicator.
struct POSFilledButtonStyle: ButtonStyle {
    private let size: POSButtonSize
    private let isLoading: Bool

    init(size: POSButtonSize, isLoading: Bool = false) {
        self.size = size
        self.isLoading = isLoading
    }

    func makeBody(configuration: Configuration) -> some View {
        POSButton(configuration: configuration, variant: .filled, size: size, isLoading: isLoading)
    }
}

/// Outlined button style in POS.
struct POSOutlinedButtonStyle: ButtonStyle {
    private let size: POSButtonSize

    init(size: POSButtonSize) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        POSButton(configuration: configuration, variant: .outlined, size: size, isLoading: false)
    }
}

/// Button style in POS that has variants for filled and outlined buttons and different sizes.
struct POSButtonStyle: ButtonStyle {
    let variant: POSButtonVariant
    let size: POSButtonSize

    func makeBody(configuration: Configuration) -> some View {
        POSButton(configuration: configuration, variant: variant, size: size, isLoading: false)
    }
}

private struct POSButton: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration
    let variant: POSButtonVariant
    let size: POSButtonSize
    let isLoading: Bool

    var body: some View {
        Group {
            containerView {
                if isLoading {
                    progressView
                } else {
                    configuration.label
                }
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

    @ViewBuilder
    private func containerView(@ViewBuilder content: () -> some View) -> some View {
        switch size {
        case .normal:
            HStack {
                Spacer()
                content()
                Spacer()
            }
        case .extraSmall:
            content()
        }
    }

    private var progressView: some View {
        ProgressView()
            .progressViewStyle(POSButtonProgressViewStyle(size: size.progressViewDimensions.size, lineWidth: size.progressViewDimensions.lineWidth))
            .padding(
                .init(
                    top: size.additionalPadding.vertical,
                    leading: size.additionalPadding.horizontal,
                    bottom: size.additionalPadding.vertical,
                    trailing: size.additionalPadding.horizontal
                )
            )
    }

    private var backgroundColor: Color {
        switch (variant, isEnabled) {
        case (.filled, true):
                .posPrimaryContainer
        case (.filled, false):
                isLoading ? .posPrimaryContainer : .posDisabledContainer
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

// MARK: - POSButton Constants

private extension POSButton {
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
                .posBodyEmphasized
        case .extraSmall:
                .posDetailEmphasized
        }
    }
}

private extension POSButtonSize {
    var progressViewDimensions: (size: CGFloat, lineWidth: CGFloat) {
        switch self {
        case .normal:
            (size: 32, lineWidth: 10)
        case .extraSmall:
            (size: 20, lineWidth: 6)
        }
    }

    /// The internal use of `IndefiniteCircularProgressViewStyle` progress style results in half of the line width drawn outside of the progress view.
    /// This additional padding is thus adjusted by the partial line width to achieve the expected padding in design.
    var additionalPadding: (vertical: CGFloat, horizontal: CGFloat) {
        switch self {
        case .normal:
            (vertical: progressViewDimensions.lineWidth * 0.5, horizontal: progressViewDimensions.lineWidth * 0.5)
        case .extraSmall:
            (vertical: 2 + progressViewDimensions.lineWidth * 0.5, horizontal: 16 + progressViewDimensions.lineWidth * 0.5)
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

                loadingPreviewSection(title: "Loading Buttons - Normal", size: .normal)

                loadingPreviewSection(title: "Loading Buttons - Extra Small", size: .extraSmall)

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

    private func loadingPreviewSection(title: String, size: POSButtonSize) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            Button("Enabled Button") {}
                .buttonStyle(POSFilledButtonStyle(size: size, isLoading: true))

            Button("Disabled Button") {}
                .buttonStyle(POSFilledButtonStyle(size: size, isLoading: true))
                .disabled(true)
        }
    }
}

#Preview("Button Styles") {
    POSButtonStyle_Previews()
}

#endif
