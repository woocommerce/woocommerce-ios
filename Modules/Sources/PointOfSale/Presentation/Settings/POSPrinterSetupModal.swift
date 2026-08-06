import SwiftUI
import struct Yosemite.PrinterDevice
import enum WooFoundation.BluetoothAuthorization
import protocol WooFoundation.BluetoothAuthorizationProviding

/// Drives the receipt-printer setup flow from a `POSPrinterConnectionController`, presenting
/// pairing, discovery, connection, and error states. Dismisses itself once a printer connects.
struct POSPrinterSetupModal: View {
    @Binding var isPresented: Bool
    let controller: POSPrinterConnectionController
    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        // Size a single `modalCore` via these bounds so it keeps one view identity across size-class
        // changes on iPad, preserving any state internal to the modal.
        modalCore
            .frame(minWidth: modalMinWidth, maxWidth: modalMaxWidth,
                   minHeight: modalMinHeight, maxHeight: modalMaxHeight)
            .fixedSize(horizontal: false, vertical: !isCompactWidth)
            .onChange(of: controller.isConnected) { _, isConnected in
                if isConnected {
                    isPresented = false
                }
            }
            .onDisappear {
                Task {
                    await controller.cancelSetup()
                }
            }
    }

    // In compact width the modal fills the screen to avoid the cramped iPad-tuned card, so its bounds
    // are pinned to the parent. In regular width it hugs its content up to a share of the parent.
    private var modalMinWidth: CGFloat? {
        isCompactWidth ? parentSize.width : nil
    }

    private var modalMaxWidth: CGFloat {
        isCompactWidth ? parentSize.width : parentSize.width * Constants.parentWidthRatio
    }

    private var modalMinHeight: CGFloat? {
        isCompactWidth ? parentSize.height : nil
    }

    private var modalMaxHeight: CGFloat {
        isCompactWidth ? parentSize.height : parentSize.height * Constants.maxParentHeightRatio
    }

    private var modalCore: some View {
        VStack(spacing: POSSpacing.xLarge) {
            ScrollView(showsIndicators: false) {
                HStack {
                    Spacer()
                    POSPrinterSetupContent(controller: controller)
                    Spacer()
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: [.vertical])

            if let buttonConfiguration {
                PointOfSaleFlowButtonsView(configuration: buttonConfiguration)
            }
        }
        .posModalCloseButton(action: {
            isPresented = false
        })
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
    }
}

// MARK: - Content per discovery state

/// The step-specific body of the printer setup modal, switching on the controller's discovery state
/// to present pairing guidance, progress, results, or errors.
private struct POSPrinterSetupContent: View {
    let controller: POSPrinterConnectionController

    var body: some View {
        switch controller.discoveryState {
        case .idle:
            messageContent(icon: PointOfSaleAssets.printer.decorativeImage,
                           title: Localization.pairTitle,
                           message: pairMessage)
        case .searching:
            progressContent(message: Localization.searching)
        case .noPrintersFound:
            messageContent(icon: PointOfSaleAssets.printer.decorativeImage,
                           title: Localization.noPrintersTitle,
                           message: Localization.noPrintersMessage)
        case .foundOne(let device):
            messageContent(icon: PointOfSaleAssets.printer.decorativeImage,
                           title: String(format: Localization.foundPrinterFormat, device.name),
                           message: Localization.foundPrinterMessage)
        case .foundMultiple(let devices):
            deviceList(devices)
        case .connecting(let device):
            progressContent(message: String(format: Localization.connectingFormat, device.name))
        case .error:
            messageContent(icon: PointOfSaleAssets.exclamationMark.decorativeImage,
                           title: Localization.errorTitle,
                           message: Localization.errorMessage)
        }
    }

    /// On the pairing step, call out the disabled Bluetooth permission when that's the blocker;
    /// otherwise show the standard pair-in-Settings guidance.
    private var pairMessage: String {
        switch controller.bluetoothAuthorization {
        case .denied:
            return Localization.enableBluetoothInstruction
        case .notDetermined, .allowed:
            return Localization.pairInstruction
        }
    }

    private func messageContent(icon: Image, title: String, message: String) -> some View {
        VStack(spacing: POSSpacing.xLarge) {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(Color.posOnSurface)

            VStack(alignment: .center, spacing: POSSpacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .foregroundColor(.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func progressContent(message: String) -> some View {
        VStack(spacing: POSSpacing.xLarge) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle())
                .padding(Constants.spinnerStrokeOverflow)

            Text(message)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .multilineTextAlignment(.center)
        }
    }

    private func deviceList(_ devices: [PrinterDevice]) -> some View {
        VStack(spacing: POSSpacing.large) {
            Text(Localization.severalPrintersTitle)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            if controller.isDiscovering {
                scanningIndicator
            }

            VStack(spacing: POSSpacing.none) {
                ForEach(devices) { device in
                    HStack(spacing: POSSpacing.medium) {
                        Text(device.name)
                            .font(.posBodyLargeRegular())
                            .foregroundStyle(Color.posOnSurface)
                        Spacer()
                        Button(Localization.connectRowButton) {
                            controller.connect(to: device)
                        }
                        .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
                        .accessibilityLabel(String(format: Localization.connectRowAccessibilityFormat, device.name))
                    }
                    .padding(.vertical, POSPadding.small)
                }
            }
        }
    }

    private var scanningIndicator: some View {
        HStack(spacing: POSSpacing.medium) {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle(size: Constants.scanningSpinnerSize,
                                                        lineWidth: Constants.scanningSpinnerLineWidth))
            Text(Localization.scanningForPrinters)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurface)
        }
    }
}

// MARK: - Content constants and strings
private extension POSPrinterSetupContent {
    enum Constants {
        static let iconSize: CGFloat = 112
        /// The spinner's stroke is centered on its radius, so it overflows the style's frame by
        /// half the line width (default 48). Pad by that amount so the enclosing ScrollView
        /// doesn't clip the donut top and bottom.
        static let spinnerStrokeOverflow: CGFloat = 24
        static let scanningSpinnerSize: CGFloat = 20
        static let scanningSpinnerLineWidth: CGFloat = 4
    }

    enum Localization {
        static let pairTitle = NSLocalizedString(
            "pos.printerSetup.pair.title",
            value: "Pair your printer",
            comment: "Title for the printer pairing step in POS settings.")

        static let pairInstruction = NSLocalizedString(
            "pos.printerSetup.pair.pairInSettingsInstruction",
            value: "Turn on your Star Micronics receipt printer, then pair it in the Settings app "
                + "under Bluetooth. Once it's paired, tap Connect printer to find it.",
            comment: "Instruction for pairing a receipt printer in POS settings. Tells the user to "
                + "pair the printer in the iOS Settings app under Bluetooth before searching in the app.")

        static let enableBluetoothInstruction = NSLocalizedString(
            "pos.printerSetup.pair.enableBluetoothInstruction",
            value: "Bluetooth access is turned off. Tap Open Settings to turn it on, "
                + "then pair your printer under Bluetooth.",
            comment: "Instruction shown on the receipt printer pairing step when the app's Bluetooth "
                + "permission is disabled, telling the merchant to enable it in the iOS Settings app.")

        static let searching = NSLocalizedString(
            "pos.printerSetup.searching",
            value: "Searching for printers…",
            comment: "Message shown while discovering receipt printers in POS settings.")

        static let foundPrinterFormat = NSLocalizedString(
            "pos.printerSetup.foundOne.titleFormat",
            value: "Found %1$@",
            comment: "Title shown when a single receipt printer is discovered in POS settings. "
                + "%1$@ is the printer name.")

        static let foundPrinterMessage = NSLocalizedString(
            "pos.printerSetup.foundOne.message",
            value: "Do you want to connect to this printer?",
            comment: "Message asking the merchant to confirm connecting to the discovered receipt printer in POS settings.")

        static let severalPrintersTitle = NSLocalizedString(
            "pos.printerSetup.foundMultiple.title",
            value: "Several printers found",
            comment: "Title shown above the list of discovered receipt printers in POS settings.")

        static let scanningForPrinters = NSLocalizedString(
            "pos.printerSetup.foundMultiple.scanningLabel",
            value: "Scanning for printers",
            comment: "Label shown next to a spinner while receipt printer scanning continues in POS settings.")

        static let connectRowButton = NSLocalizedString(
            "pos.printerSetup.foundMultiple.connectButton",
            value: "Connect",
            comment: "Button in a printer row to connect to that receipt printer in POS settings.")

        static let connectRowAccessibilityFormat = NSLocalizedString(
            "pos.printerSetup.foundMultiple.connectButton.accessibilityLabel",
            value: "Connect to %1$@",
            comment: "Accessibility label for the connect button in a printer row in POS settings. "
                + "%1$@ is the printer name.")

        static let connectingFormat = NSLocalizedString(
            "pos.printerSetup.connecting.format",
            value: "Connecting to %1$@…",
            comment: "Message shown while connecting to a receipt printer. %1$@ is the printer name.")

        static let noPrintersTitle = NSLocalizedString(
            "pos.printerSetup.noPrinters.title",
            value: "No printers found",
            comment: "Title shown when no receipt printers are discovered in POS settings.")

        static let noPrintersMessage = NSLocalizedString(
            "pos.printerSetup.noPrinters.pairInSettingsMessage",
            value: "Make sure your printer is on and paired in the Settings app under Bluetooth, "
                + "then search again.",
            comment: "Message shown when no receipt printers are discovered in POS settings.")

        static let errorTitle = NSLocalizedString(
            "pos.printerSetup.error.title",
            value: "Something went wrong",
            comment: "Title shown when receipt printer setup fails in POS settings.")

        static let errorMessage = NSLocalizedString(
            "pos.printerSetup.error.message",
            value: "We couldn't connect to your printer. Please try again.",
            comment: "Message shown when receipt printer setup fails in POS settings.")
    }
}

// MARK: - Buttons per discovery state
private extension POSPrinterSetupModal {
    var buttonConfiguration: PointOfSaleFlowButtonConfiguration? {
        switch controller.discoveryState {
        case .idle:
            return setupButtons(primaryTitle: Localization.connectButton)
        case .noPrintersFound:
            return setupButtons(primaryTitle: Localization.searchAgainButton)
        case .error:
            return setupButtons(primaryTitle: Localization.searchAgainButton)
        case .foundOne(let device):
            return .init(
                primaryButton: .init(title: Localization.connectToPrinterButton, action: {
                    controller.connect(to: device)
                }),
                secondaryButton: .init(title: Localization.keepSearchingButton, action: {
                    controller.keepSearching(skipping: device)
                }))
        case .foundMultiple:
            return .init(
                primaryButton: nil,
                secondaryButton: .init(title: Localization.cancelButton, action: {
                    isPresented = false
                }))
        case .searching, .connecting:
            return nil
        }
    }

    func setupButtons(primaryTitle: String) -> PointOfSaleFlowButtonConfiguration {
        // While the app's Bluetooth permission is off, discovery can't run, so Open Settings is the
        // only action worth offering.
        if controller.bluetoothAuthorization == .denied {
            return .init(primaryButton: .init(title: Localization.settingsButton, action: {
                openDeviceSettings()
            }),
                         secondaryButton: nil)
        }
        return .init(primaryButton: .init(title: primaryTitle, action: {
            controller.startDiscovery()
        }),
                     secondaryButton: nil)
    }

    func openDeviceSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - Constants
private extension POSPrinterSetupModal {
    enum Constants {
        static let maxParentHeightRatio: CGFloat = 0.9
        static let parentWidthRatio: CGFloat = 0.75
    }

    enum Localization {
        static let connectButton = NSLocalizedString(
            "pos.printerSetup.connectButton",
            value: "Connect printer",
            comment: "Button to start printer discovery after pairing in POS settings.")

        static let settingsButton = NSLocalizedString(
            "pos.printerSetup.settingsButton",
            value: "Open Settings",
            comment: "Secondary button that opens the app's Settings page, where Bluetooth can be enabled, during receipt printer setup in POS.")

        static let connectToPrinterButton = NSLocalizedString(
            "pos.printerSetup.foundOne.connectButton",
            value: "Connect to printer",
            comment: "Button to connect to the single discovered receipt printer in POS settings.")

        static let keepSearchingButton = NSLocalizedString(
            "pos.printerSetup.foundOne.keepSearchingButton",
            value: "Keep Searching",
            comment: "Button to skip the discovered receipt printer and keep searching in POS settings.")

        static let cancelButton = NSLocalizedString(
            "pos.printerSetup.foundMultiple.cancelButton",
            value: "Cancel",
            comment: "Button to close the receipt printer setup without connecting in POS settings.")

        static let searchAgainButton = NSLocalizedString(
            "pos.printerSetup.searchAgainButton",
            value: "Search again",
            comment: "Button to retry receipt printer discovery in POS settings.")
    }
}

#if DEBUG
#Preview {
    POSPrinterSetupModal(isPresented: .constant(true),
                         controller: POSPrinterConnectionController(service: POSReceiptPrinterPreviewService()))
}

#Preview("Bluetooth disabled") {
    POSPrinterSetupModal(
        isPresented: .constant(true),
        controller: POSPrinterConnectionController(
            service: POSReceiptPrinterPreviewService(),
            bluetoothAuthorizationProvider: PreviewBluetoothAuthorizationProvider(current: .denied))
    )
}

#Preview("Printer found") {
    let controller = POSPrinterConnectionController(
        service: POSReceiptPrinterPreviewService(
            devices: [PrinterDevice(id: "1", name: "Star TSP100")],
            keepDiscovering: true))
    controller.startDiscovery()
    return POSPrinterSetupModal(isPresented: .constant(true), controller: controller)
}

#Preview("Discovery error") {
    let controller = POSPrinterConnectionController(
        service: POSReceiptPrinterPreviewService(failsDiscovery: true))
    controller.startDiscovery()
    return POSPrinterSetupModal(isPresented: .constant(true), controller: controller)
}

#Preview("Failed to connect") {
    let device = PrinterDevice(id: "1", name: "Star TSP100")
    let controller = POSPrinterConnectionController(
        service: POSReceiptPrinterPreviewService(devices: [device], failsToConnect: true))
    controller.connect(to: device)
    return POSPrinterSetupModal(isPresented: .constant(true), controller: controller)
}

#Preview("Several printers found") {
    let controller = POSPrinterConnectionController(
        service: POSReceiptPrinterPreviewService(
            devices: [PrinterDevice(id: "1", name: "Star TSP100"),
                      PrinterDevice(id: "2", name: "Star mC-Print3")],
            keepDiscovering: true))
    controller.startDiscovery()
    return POSPrinterSetupModal(isPresented: .constant(true), controller: controller)
}

private struct PreviewBluetoothAuthorizationProvider: BluetoothAuthorizationProviding {
    let current: BluetoothAuthorization
}
#endif
