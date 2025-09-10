import SwiftUI

/// The size variant of the POS button.
enum POSButtonSize {
    case normal
    case extraSmall
}

/// Button state for different visual presentations
enum POSButtonState {
    case idle
    case loading
    case success
}

/// Filled button style in POS that can show loading and success states.
struct POSFilledButtonStyle: ButtonStyle {
    private let size: POSButtonSize
    private let state: POSButtonState

    init(size: POSButtonSize, isLoading: Bool = false) {
        self.size = size
        self.state = isLoading ? .loading : .idle
    }
    
    init(size: POSButtonSize, state: POSButtonState) {
        self.size = size
        self.state = state
    }

    func makeBody(configuration: Configuration) -> some View {
        POSButtonStyleInternal(configuration: configuration, variant: .filled, size: size, state: state)
            .disabled(state != .idle)
    }
}

/// Outlined button style in POS.
struct POSOutlinedButtonStyle: ButtonStyle {
    private let size: POSButtonSize

    init(size: POSButtonSize) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        POSButtonStyleInternal(configuration: configuration, variant: .outlined, size: size, state: .idle)
    }
}


/// The visual variant of the POS button.
fileprivate enum POSButtonVariant {
    case filled
    case outlined
}

private struct POSButtonStyleInternal: View {
    @Environment(\.isEnabled) var isEnabled

    let configuration: ButtonStyleConfiguration
    let variant: POSButtonVariant
    let size: POSButtonSize
    let state: POSButtonState

    var body: some View {
        Group {
            containerView {
                ZStack(alignment: .center) {
                    configuration.label
                        .opacity(state == .idle ? 1 : 0)
                    progressView
                        .renderedIf(state == .loading)
                    successView
                        .renderedIf(state == .success)
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
    }

    private var successView: some View {
        Image(systemName: "checkmark.circle")
            .font(size == .normal ? .title2 : .body)
            .foregroundColor(.posOnPrimaryContainer)
    }

    private var backgroundColor: Color {
        switch (variant, isEnabled) {
        case (.filled, true):
                .posPrimaryContainer
        case (.filled, false):
                state != .idle ? .posPrimaryContainer : .posDisabledContainer
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

// MARK: - POSButtonStyleInternal Constants

private extension POSButtonStyleInternal {
    enum Constants {
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
        static let borderStrokeWidth: CGFloat = 2.0
    }
}

// MARK: - POSButtonSize Extensions

private extension POSButtonSize {
    var padding: (vertical: CGFloat, horizontal: CGFloat) {
        switch self {
        case .normal:
            (vertical: POSPadding.large, horizontal: POSPadding.large)
        case .extraSmall:
            (vertical: POSPadding.small, horizontal: POSPadding.medium)
        }
    }

    var font: POSFontStyle {
        switch self {
        case .normal:
                .posBodyLargeBold
        case .extraSmall:
                .posBodyMediumBold
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
}

// MARK: - Preview

#if DEBUG

struct POSButtonStyle_Previews: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: POSSpacing.xLarge) {
                previewSection(title: "Filled Buttons - Normal",
                               variant: .filled, size: .normal)

                previewSection(title: "Filled Buttons - Extra Small",
                               variant: .filled, size: .extraSmall)

                previewSection(title: "Outlined Buttons - Normal",
                               variant: .outlined, size: .normal)

                previewSection(title: "Outlined Buttons - Extra Small",
                               variant: .outlined, size: .extraSmall)

                LoadingPreviewSection(title: "Loading Buttons - Normal", size: .normal)

                LoadingPreviewSection(title: "Loading Buttons - Extra Small", size: .extraSmall)
                
                LoadingStatePreviewSection(title: "Loading State Buttons - Normal", size: .normal)
                
                LoadingStatePreviewSection(title: "Loading State Buttons - Extra Small", size: .extraSmall)

                // Example with long text
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    Text("Long Text Examples")
                        .font(.headline)

                    Button("This is a very long button text that might wrap to multiple lines") {}
                        .buttonStyle(POSFilledButtonStyle(size: .normal))

                    Button("Long text in small size button that might need to wrap") {}
                        .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
                }
            }
            .padding()
        }
    }

    private func previewSection(title: String, variant: POSButtonVariant, size: POSButtonSize) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(title)
                .font(.headline)

            switch variant {
            case .filled:
                Button("Enabled Button") {}
                    .buttonStyle(POSFilledButtonStyle(size: size))

                Button("Disabled Button") {}
                    .buttonStyle(POSFilledButtonStyle(size: size))
                    .disabled(true)
            case .outlined:
                Button("Enabled Button") {}
                    .buttonStyle(POSOutlinedButtonStyle(size: size))

                Button("Disabled Button") {}
                    .buttonStyle(POSOutlinedButtonStyle(size: size))
                    .disabled(true)
            }
        }
    }
}

private struct LoadingPreviewSection: View {
    let title: String
    let size: POSButtonSize
    @State private var showsLoadingState: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(title)
                .font(.headline)

            Button("Show loading state") {
                showsLoadingState.toggle()
            }
            .buttonStyle(POSFilledButtonStyle(size: size, isLoading: showsLoadingState))

            Button("Show loading state in\nmultiple\nlines") {
                showsLoadingState.toggle()
            }
            .buttonStyle(POSFilledButtonStyle(size: size, isLoading: showsLoadingState))

            Button("Enabled Loading Button") {}
                .buttonStyle(POSFilledButtonStyle(size: size, isLoading: true))

            Button("Disabled Loading Button") {}
                .buttonStyle(POSFilledButtonStyle(size: size, isLoading: true))
                .disabled(true)
        }
    }
}

private struct LoadingStatePreviewSection: View {
    let title: String
    let size: POSButtonSize
    @State private var currentState: POSButtonState = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(title)
                .font(.headline)

            Button("Cycle States") {
                switch currentState {
                case .idle:
                    currentState = .loading
                case .loading:
                    currentState = .success
                case .success:
                    currentState = .idle
                }
            }
            .buttonStyle(POSFilledButtonStyle(size: size, state: currentState))

            Button("Idle State") {}
                .buttonStyle(POSFilledButtonStyle(size: size, state: .idle))

            Button("Loading State") {}
                .buttonStyle(POSFilledButtonStyle(size: size, state: .loading))

            Button("Success State") {}
                .buttonStyle(POSFilledButtonStyle(size: size, state: .success))
        }
    }
}

#Preview("Button Styles") {
    POSButtonStyle_Previews()
}

#endif
