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
                    .foregroundColor(.posOnSurface)
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
    @Environment(\.posAnalytics) private var analytics
    let scanner: PointOfSaleBarcodeScannerType

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
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
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)
            }

            Button {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.barcodeScannerSetupOpenSystemSettingsTapped(scanner: scanner))

                guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(targetURL)
            } label: {
                Text(Localization.settingsButtonTitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posPrimaryContainer)
                    .underline()
            }
            .padding(.top, POSSpacing.large)
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
            value: "Go to your device settings",
            comment: "Button title to open device Settings for scanner pairing"
        )
        static let title = NSLocalizedString(
            "pos.barcodeScannerSetup.pairing.title",
            value: "Pair your scanner",
            comment: "Title for the scanner pairing step"
        )
        static let instructionFormat = NSLocalizedString(
            "pos.barcodeScannerSetup.pairing.instruction.format",
            value: "Enable Bluetooth and select your %1$@ scanner in the iOS Bluetooth settings. The scanner will beep and show a solid LED when paired.",
            comment: "Instruction for pairing scanner via device settings with feedback indicators. %1$@ is the scanner model name."
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
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder private var successIcon: some View {
        ZStack {
            Circle()
                .frame(width: 88, height: 88)
                .foregroundColor(.posSuccess)
            Image(PointOfSaleAssets.successCheck.imageName)
                .renderingMode(.template)
                .resizable()
                .frame(width: 36, height: 36)
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
                    .foregroundColor(.posOnSurface)
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
            value: "Please check the scanner's manual and reset it to factory settings, then retry the setup flow.",
            comment: "Instruction shown when scanner setup encounters an error, suggesting troubleshooting steps"
        )
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Barcode View - HID Setup") {
    PointOfSaleBarcodeScannerBarcodeView(
        title: "Star BSH-20B setup",
        instruction: "Use your barcode scanner to scan the code below to enable Bluetooth HID mode.",
        barcode: .starBsh20SetupBarcode
    )
}

@available(iOS 17.0, *)
#Preview("Barcode View - Barcode Setup") {
    PointOfSaleBarcodeScannerBarcodeView(
        title: "Scanner setup",
        instruction: "Use your barcode scanner to scan the code below to enable Bluetooth HID mode.",
        barcode: .netum1228BCHIDBarcode
    )
}

@available(iOS 17.0, *)
#Preview("Pairing View - Netum 1228BC") {
    PointOfSaleBarcodeScannerPairingView(scanner: .netum1228BC)
}

@available(iOS 17.0, *)
#Preview("Test View - Normal") {
    PointOfSaleBarcodeScannerTestBarcodeView(
        scanTester: PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: {},
            onTestFailure: { _ in },
            onTestTimeout: {},
            barcodeDefinition: .ean13
        ),
        timerCompleted: false
    )
}

@available(iOS 17.0, *)
#Preview("Test View - Timeout") {
    PointOfSaleBarcodeScannerTestBarcodeView(
        scanTester: PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: {},
            onTestFailure: { _ in },
            onTestTimeout: {},
            barcodeDefinition: .ean13
        ),
        timerCompleted: true
    )
}

@available(iOS 17.0, *)
#Preview("Setup Complete View") {
    PointOfSaleBarcodeScannerSetupCompleteView()
}

@available(iOS 17.0, *)
#Preview("Error View") {
    PointOfSaleBarcodeScannerErrorView()
}
