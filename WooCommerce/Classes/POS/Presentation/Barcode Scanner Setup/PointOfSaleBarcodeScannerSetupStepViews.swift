import SwiftUI

// TODO: Remove this view when all flows are complete
struct PointOfSaleBarcodeScannerWelcomeView: View {
    let title: String

    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Text(title)
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)

            Text("TODO: Implement \(title) setup flow")
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Button Customizations
@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerWelcomeButtonCustomization: PointOfSaleBarcodeScannerButtonCustomization {
    func customizeButtons(for flow: PointOfSaleBarcodeScannerSetupFlow) -> PointOfSaleFlowButtonConfiguration {
        return PointOfSaleFlowButtonConfiguration(
            primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig(
                title: Localization.doneButtonTitle,
                action: { flow.nextStep() }
            ),
            secondaryButton: nil
        )
    }

    private enum Localization {
        static let doneButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.done.button.title",
            value: "Done",
            comment: "Title for the done button in barcode scanner setup navigation"
        )
    }
}
