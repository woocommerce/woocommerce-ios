import SwiftUI

struct POSFlowButtonsView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isPOSModalStepFlow) private var isStepFlow

    let configuration: PointOfSaleFlowButtonConfiguration

    static func visibleConfiguration(for configuration: PointOfSaleFlowButtonConfiguration,
                                     isStepFlow: Bool) -> PointOfSaleFlowButtonConfiguration {
        isStepFlow ? configuration.removingBackButtons() : configuration
    }

    private var visibleConfiguration: PointOfSaleFlowButtonConfiguration {
        Self.visibleConfiguration(for: configuration, isStepFlow: isStepFlow)
    }

    static func usesStackedLayout(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        Group {
            if Self.usesStackedLayout(horizontalSizeClass: horizontalSizeClass) {
                VStack(spacing: metrics.spacing.medium) {
                    primaryButton
                    secondaryButton
                }
            } else {
                HStack(spacing: metrics.spacing.medium) {
                    secondaryButton
                    primaryButton
                }
            }
        }
        .geometryGroup()
        .posModalFlowBackAction(enabled: isStepFlow && configuration.backButton != nil,
                                actionEnabled: configuration.backButton?.isEnabled ?? true,
                                accessibilityIdentifier: configuration.backButton?.accessibilityIdentifier) {
            configuration.backButton?.action()
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        if let primaryButton = visibleConfiguration.primaryButton {
            button(for: primaryButton)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryButton = visibleConfiguration.secondaryButton {
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
        /// In a phone flow with steps, the header back arrow replaces it.
        let isBack: Bool
        let action: () -> Void

        init(
            title: String,
            isEnabled: Bool = true,
            accessibilityIdentifier: String? = nil,
            isBack: Bool = false,
            action: @escaping () -> Void,
        ) {
            self.title = title
            self.isEnabled = isEnabled
            self.accessibilityIdentifier = accessibilityIdentifier
            self.isBack = isBack
            self.action = action
        }
    }

    var backButton: ButtonConfig? {
        [primaryButton, secondaryButton].compactMap { $0 }.first { $0.isBack }
    }

    func removingBackButtons() -> PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: primaryButton?.isBack == true ? nil : primaryButton,
              secondaryButton: secondaryButton?.isBack == true ? nil : secondaryButton)
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
    VStack(spacing: POSMetrics.regular.spacing.xLarge) {
        POSFlowButtonsView(configuration: .preview())
        POSFlowButtonsView(configuration: .preview(secondary: nil))
        POSFlowButtonsView(configuration: .preview(primary: nil))
        POSFlowButtonsView(configuration: .preview(primary: "Weiter zur Einrichtung",
                                                           secondary: "Zurück zur Auswahl"))
    }
    .padding(POSMetrics.regular.padding.xLarge)
    .background(Color.posSurfaceBright)
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular — side by side") {
    VStack(spacing: POSMetrics.regular.spacing.xLarge) {
        POSFlowButtonsView(configuration: .preview())
        POSFlowButtonsView(configuration: .preview(secondary: nil))
        POSFlowButtonsView(configuration: .preview(primary: nil))
        POSFlowButtonsView(configuration: .preview(primary: "Weiter zur Einrichtung",
                                                           secondary: "Zurück zur Auswahl"))
    }
    .padding(POSMetrics.regular.padding.xLarge)
    .background(Color.posSurfaceBright)
    .environment(\.horizontalSizeClass, .regular)
}

#endif
