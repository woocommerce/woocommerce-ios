import SwiftUI

// MARK: - Scanner Selection View
struct PointOfSaleBarcodeScannerSetupSelectionView: View {
    let options: [PointOfSaleBarcodeScannerSetupFlowOption]
    let onSelection: (PointOfSaleBarcodeScannerType) -> Void

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            VStack(spacing: POSSpacing.small) {
                Text(Localization.setupHeading)
                    .accessibilityAddTraits(.isHeader)
                    .font(.posHeadingBold)
                Text(Localization.setupIntroMessage)
                    .font(.posBodyLargeRegular())
            }
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: POSSpacing.medium) {
                ForEach(options) { option in
                    Button {
                        onSelection(option.scannerType)
                    } label: {
                        Text(option.title)
                    }
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
            }
        }
    }
}

// MARK: - Private Localization Extensions
private extension PointOfSaleBarcodeScannerSetupSelectionView {
    enum Localization {
        static let setupIntroMessage = NSLocalizedString(
            "pos.barcodeScannerSetup.selection.introMessage",
            value: "Select a model from the list:",
            comment: "Instruction message for selecting a barcode scanner model from the list"
        )

        static let setupHeading = NSLocalizedString(
            "pos.barcodeScannerSetup.selection.heading",
            value: "Set up a barcode scanner",
            comment: "Heading for the barcode scanner setup selection screen"
        )
    }
}
