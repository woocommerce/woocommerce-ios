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
    //TODO: WOOMOB-792
    enum Localization {
        static let settingsButtonTitle = "Go to settings"
        static let title = "Pair your scanner"
        static let instructionFormat = "Enable Bluetooth and select your %1$@ scanner in iOS Settings."
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
        static let title = "Test your scanner"
        static let instruction = "Scan the barcode to test your scanner"
        static let timeoutTitle = "No scan data found yet"
        static let timeoutInstruction = "Scan the barcode to test your scanner. If the issue continues, please check Bluetooth settings and try again."
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
        //TODO: WOOMOB-792
        static let title = "Scanner set up!"
        static let instruction = "You are ready to start scanning products. \n" +
        "Read more about barcode and QR code scanner support."
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
        static let title = "Scanning issue found"
        static let instruction = "Please check the scanner’s manual and reset it \n" +
        "to factory settings, then retry the set up flow."
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
