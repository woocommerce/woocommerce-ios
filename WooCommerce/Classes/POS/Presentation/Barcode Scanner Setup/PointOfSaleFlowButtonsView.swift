import SwiftUI

struct PointOfSaleFlowButtonsView: View {
    let configuration: PointOfSaleFlowButtonConfiguration

    var body: some View {
        HStack(spacing: POSSpacing.medium) {
            if let secondaryButton = configuration.secondaryButton {
                Button(secondaryButton.title) {
                    secondaryButton.action()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .disabled(!secondaryButton.isEnabled)
            }

            if let primaryButton = configuration.primaryButton {
                Button(primaryButton.title) {
                    primaryButton.action()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!primaryButton.isEnabled)
            }
        }
        .geometryGroup()
    }
}

// MARK: - Button Configuration
struct PointOfSaleFlowButtonConfiguration {
    let primaryButton: ButtonConfig?
    let secondaryButton: ButtonConfig?

    struct ButtonConfig {
        let title: String
        let isEnabled: Bool
        let action: () -> Void

        init(
            title: String,
            isEnabled: Bool = true,
            action: @escaping () -> Void,
        ) {
            self.title = title
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    // MARK: - Convenience Initializers
    static func noButtons() -> PointOfSaleFlowButtonConfiguration {
        .init(primaryButton: nil, secondaryButton: nil)
    }
}
