import SwiftUI
import StoreDesignSystem

struct HardwareBarcodeScannerInfoView: View {
    @State private var viewModel: HardwareBarcodeScannerInfoViewModel

    init(viewModel: HardwareBarcodeScannerInfoViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        HardwareBarcodeScannerInfoContent(testScanState: viewModel.testScanState)
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
    }
}

struct HardwareBarcodeScannerInfoContent: View {
    let testScanState: HardwareBarcodeScannerInfoViewModel.TestScanState

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            Text(Localization.title)
                .storeTextStyle(.titleLarge.emphasized)
                .foregroundStyle(Color.storeOnSurface)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, StoreSpacing.s5)
            Text(Localization.setup)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(Color.storeOnSurfaceVariant)
                .padding(.bottom, StoreSpacing.s4)
            Text(Localization.usage)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(Color.storeOnSurfaceVariant)
                .padding(.bottom, StoreSpacing.s7)
            Text(Localization.testTitle)
                .storeTextStyle(.titleMedium.strong)
                .foregroundStyle(Color.storeOnSurface)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, StoreSpacing.s3)
            Text(Localization.testInstruction)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(Color.storeOnSurfaceVariant)
                .padding(.bottom, StoreSpacing.s7)
            testArea
            if let errorHint {
                Text(errorHint)
                    .storeTextStyle(.bodyMedium)
                    .foregroundStyle(Color.storeError)
                    .padding(.top, StoreSpacing.s3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, StorePadding.p7)
        .padding(.top, StorePadding.p7)
        .padding(.bottom, StorePadding.p5)
        .animation(.easeInOut(duration: StoreMotion.selectionDuration), value: testScanState)
    }

    /// The success message takes the place of the barcode, so the sheet keeps its height.
    private var testArea: some View {
        ZStack(alignment: .top) {
            Image(.hardwareScannerTestBarcode)
                .resizable()
                .frame(height: Layout.testBarcodeHeight)
                .padding(.horizontal, StorePadding.p7)
                .padding(.vertical, StorePadding.p5)
                .frame(maxWidth: .infinity)
                .background(Color.storePaletteWhite, in: RoundedRectangle(cornerRadius: StoreRadius.medium))
                .accessibilityLabel(Localization.testBarcodeAccessibilityLabel)
                .opacity(testScanState == .success ? 0 : 1)
            if testScanState == .success {
                VStack(spacing: StoreSpacing.s5) {
                    // A symbol, since the design system icons stop at 32pt and scaling them up blurs them.
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.storePaletteWhite, Color.storeAlertGreen)
                        .frame(width: Layout.successCheckSize, height: Layout.successCheckSize)
                    Text(Localization.testSuccess)
                        .storeTextStyle(.titleMedium)
                        .foregroundStyle(Color.storeOnSurface)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var errorHint: String? {
        switch testScanState {
        case .missingEnterSuffix:
            return Localization.missingEnterSuffix
        case .wrongValue:
            return Localization.wrongValue
        case .waiting, .success:
            return nil
        }
    }
}

private extension HardwareBarcodeScannerInfoContent {
    enum Layout {
        /// Android's 88dp bars: scanners read the code at any height, taller bars only make the sheet taller.
        static let testBarcodeHeight: CGFloat = 88
        static let successCheckSize: CGFloat = 72
    }

    enum Localization {
        static let title = NSLocalizedString(
            "hardwareBarcodeScannerInfo.title",
            value: "Use a Bluetooth or USB scanner",
            comment: "Title of the sheet that explains how to use an external barcode scanner."
        )
        static let setup = NSLocalizedString(
            "hardwareBarcodeScannerInfo.setup",
            value: "Pair your scanner in your device's Bluetooth settings, or connect it with USB. Set it to keyboard (HID) mode.",
            comment: "Explains how to connect an external barcode scanner."
        )
        static let usage = NSLocalizedString(
            "hardwareBarcodeScannerInfo.usage",
            value: "Scan on the Orders and Products screens, or while creating an order. You don't need to open the camera.",
            comment: "Explains where an external barcode scanner can be used."
        )
        static let testTitle = NSLocalizedString(
            "hardwareBarcodeScannerInfo.testTitle",
            value: "Test your scanner",
            comment: "Heading of the test scan section in the external barcode scanner sheet."
        )
        static let testInstruction = NSLocalizedString(
            "hardwareBarcodeScannerInfo.testInstruction",
            value: "Scan this barcode with your scanner.",
            comment: "Asks the merchant to scan the test barcode with an external barcode scanner."
        )
        static let testSuccess = NSLocalizedString(
            "hardwareBarcodeScannerInfo.testSuccess",
            value: "Your scanner works",
            comment: "Shown when the test barcode was scanned correctly with an external barcode scanner."
        )
        static let wrongValue = NSLocalizedString(
            "hardwareBarcodeScannerInfo.wrongValue",
            value: "The scanned code doesn't match. Set your scanner to the same keyboard layout as your device.",
            comment: "Shown when an external barcode scanner sends a different code than the test barcode."
        )
        static let missingEnterSuffix = NSLocalizedString(
            "hardwareBarcodeScannerInfo.missingEnterSuffix",
            value: "Scan not finished. Set your scanner to send Enter after each barcode.",
            comment: "Shown when an external barcode scanner sends the test barcode without Enter at the end."
        )
        static let testBarcodeAccessibilityLabel = NSLocalizedString(
            "hardwareBarcodeScannerInfo.testBarcode.accessibilityLabel",
            value: "Test barcode",
            comment: "Accessibility label of the barcode to scan when testing an external barcode scanner."
        )
    }
}

#Preview("Waiting") {
    StoreSheet {
        HardwareBarcodeScannerInfoContent(testScanState: .waiting)
    }
}

#Preview("Wrong value") {
    StoreSheet {
        HardwareBarcodeScannerInfoContent(testScanState: .wrongValue)
    }
}

#Preview("Success, dark") {
    StoreSheet {
        HardwareBarcodeScannerInfoContent(testScanState: .success)
    }
    .preferredColorScheme(.dark)
}
