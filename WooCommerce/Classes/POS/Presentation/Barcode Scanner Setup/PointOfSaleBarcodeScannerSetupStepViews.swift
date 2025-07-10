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
    }
}

struct PointOfSaleBarcodeScannerBarcodeView: View {
    let title: String
    let instruction: String
    let barcode: PointOfSaleAssets

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(instruction)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }

            Image(barcode.imageName)
        }
    }
}

struct PointOfSaleBarcodeScannerPairingView: View {
    let scanner: PointOfSaleBarcodeScannerType

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            // Temporary image until finalised assets are available
            Image(systemName: "gearshape")
                .font(.system(size: 78))
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(instruction)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(targetURL)
            } label: {
                Text(Localization.settingsButtonTitle)
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
        }
    }

    private var instruction: String {
        String(format: Localization.instructionFormat, scanner.name)
    }
}

private extension PointOfSaleBarcodeScannerPairingView {
    //TODO: WOOMOB-792
    enum Localization {
        static let settingsButtonTitle = "Go to settings"
        static let title = "Pair your device"
        static let instructionFormat = "Enable Bluetooth and select your %1$@ scanner in iOS Settings."
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
