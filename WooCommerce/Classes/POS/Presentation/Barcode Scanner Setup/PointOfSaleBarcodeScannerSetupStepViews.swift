import SwiftUI

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
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }

            Image(barcode.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: Constants.maxBarcodeSize)
                .padding(POSPadding.medium)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
        }
    }
}

extension PointOfSaleBarcodeScannerBarcodeView {
    enum Constants {
        static let maxBarcodeSize: CGFloat = 168
    }
}

struct PointOfSaleBarcodeScannerPairingView: View {
    let scanner: PointOfSaleBarcodeScannerType

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            // Temporary image until finalised assets are available
            Image(decorative: PointOfSaleAssets.gears.imageName)
                .resizable()
                .frame(width: Constants.gearIconSize, height: Constants.gearIconSize)

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }

            Button {
                ServiceLocator.analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupOpenSystemSettingsTapped(scanner: scanner))

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
    enum Localization {
        static let settingsButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.pairing.settingsButton.title",
            value: "Go to settings",
            comment: "Button title to open iOS Settings for scanner pairing"
        )
        static let title = NSLocalizedString(
            "pos.barcodeScannerSetup.pairing.title",
            value: "Pair your scanner",
            comment: "Title for the scanner pairing step"
        )
        static let instructionFormat = NSLocalizedString(
            "pos.barcodeScannerSetup.pairing.instruction.format",
            value: "Enable Bluetooth and select your %1$@ scanner in iOS Settings.",
            comment: "Instruction for pairing scanner via iOS Settings. %1$@ is the scanner model name."
        )
    }

    enum Constants {
        static let gearIconSize: CGFloat = 112
    }
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerTestBarcodeView: View {
    let scanTester: PointOfSaleBarcodeScannerSetupScanTester
    let timerCompleted: Bool

    var body: some View {
        PointOfSaleBarcodeScannerBarcodeView(title: timerCompleted ? Localization.timeoutTitle : Localization.title,
                                             instruction: timerCompleted ? Localization.timeoutInstruction : Localization.instruction,
                                             barcode: scanTester.barcode)
        .barcodeScanning { result in
            scanTester.handleScan(result)
        }
        .onAppear {
            if !timerCompleted {
                scanTester.startTimer()
            }
        }
        .onDisappear {
            scanTester.stopTimer()
        }
    }

}

@available(iOS 17.0, *)
private extension PointOfSaleBarcodeScannerTestBarcodeView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.barcodeScannerSetup.test.title",
            value: "Test your scanner",
            comment: "Title for the scanner testing step"
        )
        static let instruction = NSLocalizedString(
            "pos.barcodeScannerSetup.test.instruction",
            value: "Scan the barcode to test your scanner.",
            comment: "Instruction for testing the scanner by scanning a barcode"
        )
        static let timeoutTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.test.timeout.title",
            value: "No scan data found yet",
            comment: "Title shown when scanner test times out without detecting a scan"
        )
        static let timeoutInstruction = NSLocalizedString(
            "pos.barcodeScannerSetup.test.timeout.instruction",
            value: "Scan the barcode to test your scanner. If the issue continues, please check Bluetooth settings and try again.",
            comment: "Instruction shown when scanner test times out, suggesting troubleshooting steps"
        )
    }
}

struct PointOfSaleBarcodeScannerSetupCompleteView: View {
    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            // Temporary image until finalised assets are available
            successIcon
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(Localization.instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder private var successIcon: some View {
        ZStack {
            Circle()
                .frame(width: 104, height: 104)
                .foregroundColor(.posSuccess)
            Image(PointOfSaleAssets.successCheck.imageName)
                .renderingMode(.template)
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.posOnSuccess)
        }
    }
}

private extension PointOfSaleBarcodeScannerSetupCompleteView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.barcodeScannerSetup.complete.title",
            value: "Scanner set up!",
            comment: "Title shown when scanner setup is successfully completed"
        )
        static let instruction = NSLocalizedString(
            "pos.barcodeScannerSetup.complete.instruction",
            value: "You are ready to start scanning products. \nRead more about barcode and QR code scanner support.",
            comment: "Message shown when scanner setup is complete, with additional information link"
        )
    }
}

struct PointOfSaleBarcodeScannerErrorView: View {
    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            POSErrorXMark()

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(Localization.instruction)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(POSSpacing.xLarge)
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "pos.barcodeScannerSetup.error.title",
            value: "Scanning issue found",
            comment: "Title shown when there's an error during scanner setup"
        )
        static let instruction = NSLocalizedString(
            "pos.barcodeScannerSetup.error.instruction",
            value: "Please check the scanner's manual and reset it to factory settings, then retry set up flow.",
            comment: "Instruction shown when scanner setup encounters an error, suggesting troubleshooting steps"
        )
    }
}
