import SwiftUI

struct POSFlowButtonsView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let configuration: PointOfSaleFlowButtonConfiguration

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
        /// A button that goes one step back. On phone the back arrow in the flow header replaces it.
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

    /// The same buttons without the ones that go one step back.
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
