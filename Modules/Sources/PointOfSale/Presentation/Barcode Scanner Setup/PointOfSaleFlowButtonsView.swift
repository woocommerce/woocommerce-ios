import SwiftUI

struct PointOfSaleFlowButtonsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let configuration: PointOfSaleFlowButtonConfiguration

    static func usesStackedLayout(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        Group {
            if Self.usesStackedLayout(horizontalSizeClass: horizontalSizeClass) {
                VStack(spacing: POSSpacing.medium) {
                    primaryButton
                    secondaryButton
                }
            } else {
                HStack(spacing: POSSpacing.medium) {
                    secondaryButton
                    primaryButton
                }
            }
        }
        .geometryGroup()
    }

    @ViewBuilder
    private var primaryButton: some View {
        if let primaryButton = configuration.primaryButton {
            button(for: primaryButton)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryButton = configuration.secondaryButton {
            button(for: secondaryButton)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
    }

    @ViewBuilder
    private func button(for config: PointOfSaleFlowButtonConfiguration.ButtonConfig) -> some View {
        let button = Button(config.title) {
            config.action()
        }
        .disabled(!config.isEnabled)

        if let accessibilityIdentifier = config.accessibilityIdentifier {
            button.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            button
        }
    }
}

// MARK: - Button Configuration
struct PointOfSaleFlowButtonConfiguration {
    let primaryButton: ButtonConfig?
    let secondaryButton: ButtonConfig?

    struct ButtonConfig {
        let title: String
        let isEnabled: Bool
        let accessibilityIdentifier: String?
        let action: () -> Void

        init(
            title: String,
            isEnabled: Bool = true,
            accessibilityIdentifier: String? = nil,
            action: @escaping () -> Void,
        ) {
            self.title = title
            self.isEnabled = isEnabled
            self.accessibilityIdentifier = accessibilityIdentifier
            self.action = action
        }
    }

    // MARK: - Convenience Initializers
    static func noButtons() -> PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: nil, secondaryButton: nil)
    }
}

#if DEBUG

private extension PointOfSaleFlowButtonConfiguration {
    static func preview(primary: String? = "Next", secondary: String? = "Back") -> PointOfSaleFlowButtonConfiguration {
        .init(
            primaryButton: primary.map { .init(title: $0, action: {}) },
            secondaryButton: secondary.map { .init(title: $0, action: {}) }
        )
    }
}

#Preview("Compact — stacked") {
    VStack(spacing: POSSpacing.xLarge) {
        PointOfSaleFlowButtonsView(configuration: .preview())
        PointOfSaleFlowButtonsView(configuration: .preview(secondary: nil))
        PointOfSaleFlowButtonsView(configuration: .preview(primary: nil))
        PointOfSaleFlowButtonsView(configuration: .preview(primary: "Weiter zur Einrichtung",
                                                           secondary: "Zurück zur Auswahl"))
    }
    .padding(POSPadding.xLarge)
    .background(Color.posSurfaceBright)
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular — side by side") {
    VStack(spacing: POSSpacing.xLarge) {
        PointOfSaleFlowButtonsView(configuration: .preview())
        PointOfSaleFlowButtonsView(configuration: .preview(secondary: nil))
        PointOfSaleFlowButtonsView(configuration: .preview(primary: nil))
        PointOfSaleFlowButtonsView(configuration: .preview(primary: "Weiter zur Einrichtung",
                                                           secondary: "Zurück zur Auswahl"))
    }
    .padding(POSPadding.xLarge)
    .background(Color.posSurfaceBright)
    .environment(\.horizontalSizeClass, .regular)
}

#endif
