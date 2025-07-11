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
        //TODO: WOOMOB-792
        // Note that "pos.barcodeScannerSetup.introMessage" was previously sent for translation, so don't reuse that.
        static let setupIntroMessage = "Select a model from the list:"

        // Note that "pos.barcodeScannerSetup.heading" was previously sent to translation – don't reuse
        static let setupHeading = "Set up a barcode scanner"
    }
}
